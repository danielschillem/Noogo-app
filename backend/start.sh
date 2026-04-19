#!/bin/sh
set -e

cd /var/www/html

# ── Validation APP_KEY ────────────────────────────────────────
# Render's generateValue produit un string brut, pas au format base64:xxx
# que Laravel requiert. On génère un vrai APP_KEY si nécessaire.
if [ -z "$APP_KEY" ] || ! echo "$APP_KEY" | grep -q "^base64:"; then
    echo "⚠️  APP_KEY absent ou format invalide — génération automatique..."
    export APP_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
    echo "⚠️  APP_KEY=$APP_KEY"
    echo "    → Copiez cette valeur dans Render Dashboard > Environment > APP_KEY"
    echo "    → Puis redéployez pour une clé stable entre redémarrages"
fi

echo "▶ Migrations..."
php artisan migrate --force

echo "▶ Seeding admin users..."
php artisan db:seed --class=AdminUsersSeeder --force

echo "▶ Caches Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "▶ Lien storage..."
php artisan storage:link 2>/dev/null || true

echo "▶ Démarrage PHP-FPM + Nginx (serversideup)..."
# Railway injecte PORT dynamiquement — on le mappe au port Nginx
export NGINX_HTTP_PORT=${PORT:-8080}
echo "   → Nginx écoutera sur le port $NGINX_HTTP_PORT"
# Lance le superviseur serversideup qui gère FPM + Nginx
exec /init
