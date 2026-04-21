#!/bin/sh
# Exécuté par docker-php-serversideup-entrypoint
# Numéroté 99 pour s'exécuter APRÈS les Laravel automations (migrations)
echo "▶ Seeding admin users (noogo-seed)..."
cd /var/www/html
php artisan db:seed --class=AdminUsersSeeder --force 2>&1 || echo "⚠️ Seed failed (non-fatal)"
echo "✅ Admin users seeded."
