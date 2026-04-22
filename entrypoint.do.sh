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
    # PostgreSQL 15 DO managed DB fix :
    # Utilise le port direct 25061 (hors PgBouncer) pour les migrations
    # PgBouncer (25060) fait DISCARD ALL entre transactions et peut resetter search_path
    php -r "
    \$url  = getenv('DATABASE_URL') ?: getenv('DB_URL');
    \$u    = parse_url(\$url);
    \$db   = ltrim(\$u['path'] ?? '/postgres', '/');
    \$user = \$u['user'] ?? '';
    \$pass = \$u['pass'] ?? '';
    \$host = \$u['host'];
    \$ssl  = getenv('DB_SSLMODE') ?: 'require';
    // Port 25061 = connexion directe PostgreSQL (pas PgBouncer)
    \$dsn_direct = 'pgsql:host=' . \$host . ';port=25061;dbname=' . \$db . ';sslmode=' . \$ssl;
    \$dsn_pooled = 'pgsql:host=' . \$host . ';port=' . (\$u['port'] ?? 5432) . ';dbname=' . \$db . ';sslmode=' . \$ssl;
    \$opts = [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION];
    echo \"DB: \$db, user: \$user\n\";
    foreach ([\$dsn_direct, \$dsn_pooled] as \$dsn) {
        try {
            \$pdo = new PDO(\$dsn, \$user, \$pass, \$opts);
            // Diagnostic: vérifier le current_user réel côté PostgreSQL
            \$row = \$pdo->query('SELECT current_user, session_user')->fetch(PDO::FETCH_ASSOC);
            echo \"current_user=\" . \$row['current_user'] . \", session_user=\" . \$row['session_user'] . \"\n\";
            // Utiliser le nom d'utilisateur EXPLICITE de l'URL (pas CURRENT_USER qui peut résoudre vers doadmin via PgBouncer)
            \$safeUser = str_replace('\"', '', \$user);
            // GRANT CREATE sur le schéma public avec l'utilisateur explicite
            try { \$pdo->exec(\"GRANT CREATE ON SCHEMA public TO \\\"\$safeUser\\\"\"); echo \"GRANT CREATE public OK for: \$safeUser\n\"; } catch(Exception \$e) { echo 'GRANT: ' . \$e->getMessage() . \"\n\"; }
            // ALTER ROLE avec le nom explicite
            try { \$pdo->exec(\"ALTER ROLE \\\"\$safeUser\\\" SET search_path TO public\"); echo \"ALTER ROLE search_path OK for: \$safeUser\n\"; } catch(Exception \$e) { echo 'ALTER ROLE: ' . \$e->getMessage() . \"\n\"; }
            // Vérifier l'ACL du schéma public après le GRANT
            \$acl = \$pdo->query(\"SELECT nspacl::text FROM pg_namespace WHERE nspname = 'public'\")->fetchColumn();
            echo \"public schema ACL: \$acl\n\";
            echo \"Connexion OK sur: \$dsn\n\";
            break;
        } catch(Exception \$e) {
            echo 'Connexion failed (' . \$dsn . '): ' . \$e->getMessage() . \"\n\";
        }
    }
    " 2>&1
    # Clear le cache config pour forcer la relecture depuis .env
    php artisan config:clear 2>&1 | tail -1
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
