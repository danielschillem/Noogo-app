#!/bin/sh
set -e

echo "▶ Caching config & routes..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "▶ Running migrations..."
php artisan migrate --force

echo "▶ Linking storage..."
php artisan storage:link 2>/dev/null || true

echo "▶ Starting Laravel on port ${PORT:-10000}..."
exec php artisan serve --host=0.0.0.0 --port="${PORT:-10000}"
