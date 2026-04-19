#!/bin/sh
# Exécuté par docker-php-serversideup-entrypoint AVANT /init (s6)
# Ce script est sourcé, donc les exports sont disponibles pour /init

# ── APP_KEY ──────────────────────────────────────────────────
# Génère un APP_KEY valide si absent ou mal formaté
if [ -z "$APP_KEY" ] || ! echo "$APP_KEY" | grep -q "^base64:"; then
    echo "⚠️  APP_KEY absent ou format invalide — génération automatique..."
    export APP_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
    echo "⚠️  APP_KEY généré (éphémère — définissez APP_KEY dans Railway Variables)"
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
