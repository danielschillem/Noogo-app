#!/bin/sh
# Exécuté par docker-php-serversideup-entrypoint AVANT /init (s6)
# Ce script est sourcé, donc les exports sont disponibles pour /init

# ── APP_KEY ──────────────────────────────────────────────────
# Génère un APP_KEY valide si absent ou mal formaté
if [ -z "$APP_KEY" ] || ! echo "$APP_KEY" | grep -q "^base64:"; then
    echo "⚠️  APP_KEY absent ou format invalide — génération automatique..."
    APP_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
    echo "⚠️  APP_KEY généré (éphémère — définissez APP_KEY dans Railway Variables)"
fi

export APP_KEY

# Écrire APP_KEY dans .env pour que config:cache le lise (AUTORUN)
ENV_FILE="/var/www/html/.env"
if [ -f "$ENV_FILE" ]; then
    sed -i '/^APP_KEY=/d' "$ENV_FILE"
else
    touch "$ENV_FILE"
fi
echo "APP_KEY=$APP_KEY" >> "$ENV_FILE"

# Propager dans l'environnement s6 pour tous les services
if [ -d "/run/s6/container_environment" ]; then
    printf '%s' "$APP_KEY" > /run/s6/container_environment/APP_KEY
fi

# ── PORT → NGINX_HTTP_PORT ───────────────────────────────────
# Railway injecte PORT dynamiquement. On le mappe ici AVANT que s6
# génère nginx.conf depuis nginx.conf.template (utilise NGINX_HTTP_PORT).
if [ -n "$PORT" ]; then
    export NGINX_HTTP_PORT="$PORT"
    echo "✅ PORT Railway détecté : $PORT → NGINX_HTTP_PORT=$NGINX_HTTP_PORT"
else
    echo "ℹ️  PORT non défini — NGINX_HTTP_PORT reste à ${NGINX_HTTP_PORT:-8080}"
fi
