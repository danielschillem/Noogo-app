#!/bin/sh
# =============================================================
# Noogo — Entrypoint DigitalOcean
# 1. Génère APP_KEY si absent
# 2. Écrit le .env depuis les variables d'environnement
# 3. Lance les optimisations Laravel (config/route/view cache)
# 4. Démarre nginx + php-fpm via supervisord
# 5. Exécute les migrations en arrière-plan (évite timeout healthcheck)
# =============================================================
set -e

echo "🚀 Noogo — démarrage du conteneur..."

# ── APP_KEY ───────────────────────────────────────────────────
if [ -z "$APP_KEY" ] || ! echo "$APP_KEY" | grep -q "^base64:"; then
    echo "⚠️  APP_KEY absent — génération automatique"
    echo "   → Définissez APP_KEY dans les variables d'environnement DigitalOcean"
    APP_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
fi

# ── Écriture du .env ──────────────────────────────────────────
ENV_FILE="/var/www/html/.env"
: > "$ENV_FILE"

echo "APP_KEY=$APP_KEY" >> "$ENV_FILE"
[ -n "$APP_ENV" ]           && echo "APP_ENV=$APP_ENV"               >> "$ENV_FILE"
[ -n "$APP_DEBUG" ]         && echo "APP_DEBUG=$APP_DEBUG"           >> "$ENV_FILE"
[ -n "$APP_URL" ]           && echo "APP_URL=$APP_URL"               >> "$ENV_FILE"

# Base de données — DO App Platform injecte DATABASE_URL pour les BDs gérées
[ -n "$DB_CONNECTION" ]     && echo "DB_CONNECTION=$DB_CONNECTION"   >> "$ENV_FILE"
if [ -n "$DATABASE_URL" ]; then
    echo "DB_URL=$DATABASE_URL"                                       >> "$ENV_FILE"
elif [ -n "$DB_URL" ]; then
    echo "DB_URL=$DB_URL"                                             >> "$ENV_FILE"
fi
[ -n "$DB_HOST" ]           && echo "DB_HOST=$DB_HOST"               >> "$ENV_FILE"
[ -n "$DB_PORT" ]           && echo "DB_PORT=$DB_PORT"               >> "$ENV_FILE"
[ -n "$DB_DATABASE" ]       && echo "DB_DATABASE=$DB_DATABASE"       >> "$ENV_FILE"
[ -n "$DB_USERNAME" ]       && echo "DB_USERNAME=$DB_USERNAME"       >> "$ENV_FILE"
[ -n "$DB_PASSWORD" ]       && echo "DB_PASSWORD=$DB_PASSWORD"       >> "$ENV_FILE"
[ -n "$DB_SSLMODE" ]        && echo "DB_SSLMODE=$DB_SSLMODE"         >> "$ENV_FILE"
# DB_SCHEMA uses default 'public' — requires: GRANT CREATE ON SCHEMA public TO "noogo-db" in DO console

# App
[ -n "$FRONTEND_URL" ]      && echo "FRONTEND_URL=$FRONTEND_URL"     >> "$ENV_FILE"
[ -n "$LOG_CHANNEL" ]       && echo "LOG_CHANNEL=$LOG_CHANNEL"       >> "$ENV_FILE"
[ -n "$SESSION_DRIVER" ]    && echo "SESSION_DRIVER=$SESSION_DRIVER" >> "$ENV_FILE"
[ -n "$CACHE_STORE" ]       && echo "CACHE_STORE=$CACHE_STORE"       >> "$ENV_FILE"

# Pusher (temps réel)
[ -n "$PUSHER_APP_ID" ]     && echo "PUSHER_APP_ID=$PUSHER_APP_ID"           >> "$ENV_FILE"
[ -n "$PUSHER_APP_KEY" ]    && echo "PUSHER_APP_KEY=$PUSHER_APP_KEY"         >> "$ENV_FILE"
[ -n "$PUSHER_APP_SECRET" ] && echo "PUSHER_APP_SECRET=$PUSHER_APP_SECRET"   >> "$ENV_FILE"
[ -n "$PUSHER_APP_CLUSTER" ] && echo "PUSHER_APP_CLUSTER=$PUSHER_APP_CLUSTER" >> "$ENV_FILE"
[ -n "$BROADCAST_CONNECTION" ] && echo "BROADCAST_CONNECTION=$BROADCAST_CONNECTION" >> "$ENV_FILE"

# Mail
[ -n "$MAIL_MAILER" ]       && echo "MAIL_MAILER=$MAIL_MAILER"               >> "$ENV_FILE"
[ -n "$MAIL_HOST" ]         && echo "MAIL_HOST=$MAIL_HOST"                   >> "$ENV_FILE"
[ -n "$MAIL_PORT" ]         && echo "MAIL_PORT=$MAIL_PORT"                   >> "$ENV_FILE"
[ -n "$MAIL_USERNAME" ]     && echo "MAIL_USERNAME=$MAIL_USERNAME"           >> "$ENV_FILE"
[ -n "$MAIL_PASSWORD" ]     && echo "MAIL_PASSWORD=$MAIL_PASSWORD"           >> "$ENV_FILE"
[ -n "$MAIL_FROM_ADDRESS" ] && echo "MAIL_FROM_ADDRESS=$MAIL_FROM_ADDRESS"   >> "$ENV_FILE"
[ -n "$MAIL_FROM_NAME" ]    && echo "MAIL_FROM_NAME=\"$MAIL_FROM_NAME\""     >> "$ENV_FILE"

# FCM v1 (Firebase)
[ -n "$FIREBASE_PROJECT_ID" ]       && echo "FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID"       >> "$ENV_FILE"
[ -n "$FIREBASE_CREDENTIALS_JSON" ] && echo "FIREBASE_CREDENTIALS_JSON=$FIREBASE_CREDENTIALS_JSON" >> "$ENV_FILE"

# Queue
echo "QUEUE_CONNECTION=database" >> "$ENV_FILE"

echo "✅ .env écrit ($(wc -l < "$ENV_FILE") variables)"

# ── Optimisations Laravel ──────────────────────────────────────
cd /var/www/html
echo "⚙️  Nettoyage des caches Laravel..."

# Supprimer tous les caches compilés entre les déploiements.
# services.php et packages.php seront régénérés par Laravel au premier boot
# (ProviderRepository + PackageManifest) avec la liste complète des providers
# issue de config/app.providers (ServiceProvider::defaultProviders()).
rm -f bootstrap/cache/config.php \
      bootstrap/cache/routes-v7.php \
      bootstrap/cache/routes.php \
      bootstrap/cache/compiled.php \
      bootstrap/cache/events.php \
      bootstrap/cache/services.php \
      bootstrap/cache/packages.php

# NE PAS appeler artisan ici : chaque commande artisan booote tout Laravel
# et peut écrire des fichiers root dans bootstrap/cache/ causant des erreurs.
# storage:link est fait via ln -sf dans le Dockerfile (build-time, sans APP_KEY).

# ── Permissions storage ────────────────────────────────────────
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# ── Répertoires temporaires nginx ──────────────────────────────
mkdir -p /tmp/nginx_client_body
chmod 777 /tmp/nginx_client_body

# ── Migrations en arrière-plan ─────────────────────────────────
# Attend que nginx soit démarré avant de toucher la DB
(
    sleep 15
    echo "📦 [migration] En attente de la base de données..."
    RETRY=0
    DB_CHECK='
        $url = getenv("DATABASE_URL") ?: getenv("DB_URL");
        if (!$url) { exit(1); }
        $u = parse_url($url);
        if (!$u || !isset($u["host"])) exit(1);
        $dsn  = "pgsql:host=" . $u["host"]
              . ";port=" . ($u["port"] ?? 5432)
              . ";dbname=" . ltrim($u["path"] ?? "/postgres", "/");
        $ssl  = getenv("DB_SSLMODE") ?: "require";
        $dsn .= ";sslmode=" . $ssl;
        try {
            new PDO($dsn, $u["user"] ?? "", $u["pass"] ?? "", [PDO::ATTR_TIMEOUT => 5]);
        } catch (Exception $e) { exit(1); }
    '
    until php -r "$DB_CHECK" 2>/dev/null; do
        RETRY=$((RETRY + 1))
        [ $RETRY -ge 60 ] && echo "❌ [migration] DB injoignable — ignoré" && exit 0
        sleep 2
    done
    echo "✅ [migration] DB prête, lancement des migrations..."
    # ── Étape 1 : Permissions via doadmin si DB_ADMIN_URL est disponible ──
    php -r "
    \$adminUrl = getenv('DB_ADMIN_URL');
    if (!\$adminUrl) { echo \"DB_ADMIN_URL absent — GRANT ignoré\n\"; exit(0); }
    \$a    = parse_url(\$adminUrl);
    \$host = \$a['host'];
    \$port = \$a['port'] ?? 5432;
    \$db   = ltrim(\$a['path'] ?? '/defaultdb', '/');
    \$user = \$a['user'] ?? '';
    \$pass = \$a['pass'] ?? '';
    \$dsn  = 'pgsql:host=' . \$host . ';port=' . \$port . ';dbname=' . \$db . ';sslmode=require';
    try {
        \$pdo = new PDO(\$dsn, \$user, \$pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        \$cu = \$pdo->query('SELECT current_user')->fetchColumn();
        echo \"Admin connecté: current_user=\$cu\n\";
        \$appUrl  = getenv('DATABASE_URL') ?: getenv('DB_URL');
        \$appUser = parse_url(\$appUrl)['user'] ?? 'noogo-db';
        \$safe    = str_replace('\"', '', \$appUser);
        \$pdo->exec(\"ALTER SCHEMA public OWNER TO \\\"\$safe\\\"\");
        echo \"ALTER SCHEMA public OWNER TO \$safe : OK\n\";
        \$pdo->exec(\"GRANT ALL PRIVILEGES ON DATABASE \\\"\$db\\\" TO \\\"\$safe\\\"\");
        \$pdo->exec(\"GRANT ALL ON SCHEMA public TO \\\"\$safe\\\"\");
        \$pdo->exec(\"ALTER ROLE \\\"\$safe\\\" SET search_path TO public\");
        echo \"GRANT ALL ON SCHEMA public → \$safe : OK\n\";
    } catch (Exception \$e) { echo 'Admin GRANT failed: ' . \$e->getMessage() . \"\n\"; }
    " 2>&1
    # ── Étape 2 : Migrations — TOUJOURS en tant que www-data ─────────
    # IMPORTANT: ne jamais lancer artisan en root — crée des fichiers root dans
    # storage/ et bootstrap/cache/ qui bloquent ensuite PHP-FPM (www-data).
    su -s /bin/sh www-data -c "cd /var/www/html && php artisan migrate --force 2>&1" || echo "⚠️ [migration] Non-fatal"
    su -s /bin/sh www-data -c "cd /var/www/html && php artisan db:seed --class=AdminUsersSeeder --force 2>&1" || true
    su -s /bin/sh www-data -c "cd /var/www/html && php artisan db:seed --class=NoogoDeliceMenuSeeder --force 2>&1" || true
    echo "✅ [migration] Terminé"
    touch /tmp/migrations_done
) &

# ── Démarrer PHP-FPM en arrière-plan ─────────────────────────
echo "🚀 Démarrage PHP-FPM..."
/usr/local/sbin/php-fpm -F &

# ── Queue Worker en arrière-plan (en tant que www-data) ──────
echo "⚙️  Démarrage Queue Worker..."
(
    sleep 20
    while true; do
        su -s /bin/sh www-data -c "cd /var/www/html && php artisan queue:work database --sleep=3 --tries=3 --max-time=3600 2>&1" || sleep 5
    done
) &

# ── Scheduler en arrière-plan (en tant que www-data) ─────────
echo "⏰ Démarrage Scheduler..."
(
    sleep 30
    WAIT=0
    until [ -f /tmp/migrations_done ] || [ $WAIT -ge 180 ]; do
        sleep 5
        WAIT=$((WAIT + 5))
    done
    [ -f /tmp/migrations_done ] && echo "⏰ Migrations OK — scheduler démarré" || echo "⚠️ Scheduler démarré sans confirmation migrations (timeout 180s)"
    while true; do
        su -s /bin/sh www-data -c "cd /var/www/html && php artisan schedule:run --no-interaction 2>&1" || true
        sleep 60
    done
) &

# ── Nginx en foreground (PID 1) ───────────────────────────────
echo "🌐 Démarrage Nginx sur :8080..."
exec nginx -g "daemon off;"
