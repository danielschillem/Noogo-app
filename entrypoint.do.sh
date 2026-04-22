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
# Schéma dédié — évite le problème de permissions PostgreSQL 15 sur 'public'
echo "DB_SCHEMA=noogo"                                                >> "$ENV_FILE"

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

echo "✅ .env écrit ($(wc -l < "$ENV_FILE") variables)"

# ── Optimisations Laravel ──────────────────────────────────────
cd /var/www/html
echo "⚙️  Cache Laravel..."
php artisan config:cache 2>&1 | tail -1
php artisan route:cache  2>&1 | tail -1
php artisan view:cache   2>&1 | tail -1
php artisan storage:link 2>/dev/null || true

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
    # PostgreSQL 15 : créer un schéma 'noogo' dont l'app user est propriétaire
    # (évite le problème de permissions sur le schéma 'public' PG15)
    php -r "
    \$url  = getenv('DATABASE_URL') ?: getenv('DB_URL');
    \$u    = parse_url(\$url);
    \$db   = ltrim(\$u['path'] ?? '/postgres', '/');
    \$user = \$u['user'] ?? '';
    \$ssl  = getenv('DB_SSLMODE') ?: 'require';
    \$dsn  = 'pgsql:host=' . \$u['host'] . ';port=' . (\$u['port'] ?? 5432)
          . ';dbname=' . \$db . ';sslmode=' . \$ssl;
    echo \"DB user: \$user, DB: \$db\n\";
    try {
        \$pdo = new PDO(\$dsn, \$user, \$u['pass'] ?? '');
        \$pdo->exec('CREATE SCHEMA IF NOT EXISTS noogo AUTHORIZATION CURRENT_USER');
        echo \"Schema noogo: créé/vérifié OK\n\";
    } catch(Exception \$e) {
        echo 'Schema noogo create failed: ' . \$e->getMessage() . \"\n\";
        // Fallback : tenter un GRANT direct sur public
        try {
            \$pdo2 = new PDO(\$dsn, \$user, \$u['pass'] ?? '');
            \$pdo2->exec(\"GRANT CREATE ON SCHEMA public TO \\\"\$user\\\"\");
            echo \"GRANT CREATE on public: OK\n\";
        } catch(Exception \$e2) {
            echo 'GRANT fallback failed: ' . \$e2->getMessage() . \"\n\";
        }
    }
    " 2>&1
    # Recache la config avec le nouveau DB_SCHEMA
    php artisan config:cache 2>&1 | tail -1
    php artisan migrate --force 2>&1 || echo "⚠️ [migration] Non-fatal"
    php artisan db:seed --class=AdminUsersSeeder --force 2>&1 || true
    echo "✅ [migration] Terminé"
) &

# ── Démarrer PHP-FPM en arrière-plan ─────────────────────────
echo "🚀 Démarrage PHP-FPM..."
/usr/local/sbin/php-fpm -F &

# ── Nginx en foreground (PID 1) ───────────────────────────────
echo "🌐 Démarrage Nginx sur :8080..."
exec nginx -g "daemon off;"
