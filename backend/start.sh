#!/bin/sh
set -e

cd /var/www/html

echo "▶ Migrations..."
php artisan migrate --force

echo "▶ Caches Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "▶ Lien storage..."
php artisan storage:link 2>/dev/null || true

echo "▶ Démarrage PHP-FPM + Nginx (serversideup)..."
# Lance le superviseur serversideup qui gère FPM + Nginx
exec /init
