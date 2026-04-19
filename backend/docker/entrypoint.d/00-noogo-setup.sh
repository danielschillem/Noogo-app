#!/bin/sh
# Exécuté par docker-php-serversideup-entrypoint AVANT /init (s6)
# ATTENTION : ce script tourne dans un subshell (. "$f") avec set -e hérité.
# On désactive set -e pour éviter qu'une commande anodine ne crash le container.
set +e

# ── APP_KEY ──────────────────────────────────────────────────
if [ -z "$APP_KEY" ] || echo "$APP_KEY" | grep -qv "^base64:"; then
    echo "⚠️  APP_KEY absent ou format invalide — génération automatique..."
    APP_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
    echo "⚠️  APP_KEY généré (éphémère — définissez APP_KEY dans Render Environment)"
fi

# Écrire TOUTES les vars critiques dans .env pour que config:cache les lise
ENV_FILE="/var/www/html/.env"
: > "$ENV_FILE"
echo "APP_KEY=$APP_KEY" >> "$ENV_FILE"
[ -n "$APP_ENV" ]       && echo "APP_ENV=$APP_ENV" >> "$ENV_FILE"
[ -n "$APP_DEBUG" ]     && echo "APP_DEBUG=$APP_DEBUG" >> "$ENV_FILE"
[ -n "$APP_URL" ]       && echo "APP_URL=$APP_URL" >> "$ENV_FILE"
[ -n "$DB_CONNECTION" ] && echo "DB_CONNECTION=$DB_CONNECTION" >> "$ENV_FILE"
[ -n "$DB_URL" ]        && echo "DB_URL=$DB_URL" >> "$ENV_FILE"
[ -n "$DB_SSLMODE" ]    && echo "DB_SSLMODE=$DB_SSLMODE" >> "$ENV_FILE"
[ -n "$FRONTEND_URL" ]  && echo "FRONTEND_URL=$FRONTEND_URL" >> "$ENV_FILE"
[ -n "$LOG_CHANNEL" ]   && echo "LOG_CHANNEL=$LOG_CHANNEL" >> "$ENV_FILE"
[ -n "$SESSION_DRIVER" ] && echo "SESSION_DRIVER=$SESSION_DRIVER" >> "$ENV_FILE"
[ -n "$CACHE_STORE" ]   && echo "CACHE_STORE=$CACHE_STORE" >> "$ENV_FILE"
echo "✅ .env écrit avec $(wc -l < "$ENV_FILE") variables"

# Propager APP_KEY dans l'environnement s6 (si le dossier existe déjà)
if [ -d "/run/s6/container_environment" ]; then
    printf '%s' "$APP_KEY" > /run/s6/container_environment/APP_KEY
fi

# ── PORT → NGINX_HTTP_PORT ───────────────────────────────────
if [ -n "$PORT" ]; then
    export NGINX_HTTP_PORT="$PORT"
    echo "✅ PORT Render détecté : $PORT → NGINX_HTTP_PORT=$NGINX_HTTP_PORT"
else
    echo "ℹ️  PORT non défini — NGINX_HTTP_PORT reste à ${NGINX_HTTP_PORT:-10000}"
fi

exit 0
