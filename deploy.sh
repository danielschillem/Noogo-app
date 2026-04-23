#!/bin/bash
# ============================================================
# deploy.sh — Script de déploiement Noogo sur VPS
# ============================================================
# Usage : chmod +x deploy.sh && ./deploy.sh
# Prérequis : PHP 8.2+, Composer 2, Node 18+, npm, MySQL
# ============================================================

set -e  # Stopper dès la première erreur

APP_DIR="/var/www/noogo"
BACKEND_DIR="$APP_DIR/backend"
DASHBOARD_DIR="$APP_DIR/dashboard"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 1. Pull du code ──────────────────────────────────────────
info "Récupération du code (git pull)..."
cd "$APP_DIR"
git pull origin develop

# ── 2. Backend Laravel ───────────────────────────────────────
info "Dépendances PHP (Composer)..."
cd "$BACKEND_DIR"
composer install --no-dev --optimize-autoloader --no-interaction

info "Vérification du fichier .env backend..."
if [ ! -f ".env" ]; then
    error ".env manquant ! Copiez .env.production.example en .env et configurez-le."
fi

info "Migrations base de données..."
php artisan migrate --force

info "Caches Laravel (config / routes / vues)..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

info "Lien symbolique storage..."
php artisan storage:link --quiet || warning "storage:link déjà créé"

info "Permissions storage & bootstrap/cache..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# ── 3. Dashboard React ───────────────────────────────────────
info "Dépendances Node (npm)..."
cd "$DASHBOARD_DIR"
npm ci --omit=dev

info "Build dashboard (Vite)..."
npm run build

info "Copie du build dans public Nginx..."
NGINX_ROOT="/var/www/html/dashboard-noogo"
mkdir -p "$NGINX_ROOT"
cp -r dist/* "$NGINX_ROOT/"
chown -R www-data:www-data "$NGINX_ROOT"

# ── 4. Rechargement PHP-FPM & Nginx ─────────────────────────
info "Rechargement des services..."
systemctl reload php8.2-fpm  2>/dev/null || warning "php8.2-fpm non trouvé, essayez php8.3-fpm"
systemctl reload nginx

info "✅ Déploiement terminé avec succès !"

# ── Config Nginx (pour référence, à copier dans /etc/nginx/sites-available/noogo) ──
# ─────────────────────────────────────────────────────────────────────────────────
# server {
#     listen 80;
#     server_name noogo-e5ygx.ondigitalocean.app;
#     return 301 https://$host$request_uri;
# }
#
# server {
#     listen 443 ssl http2;
#     server_name noogo-e5ygx.ondigitalocean.app;
#
#     ssl_certificate     /etc/letsencrypt/live/noogo-e5ygx.ondigitalocean.app/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/noogo-e5ygx.ondigitalocean.app/privkey.pem;
#
#     # Dashboard React (SPA)
#     root /var/www/html/dashboard-noogo;
#     index index.html;
#     location / {
#         try_files $uri $uri/ /index.html;
#     }
#
#     # API Laravel
#     location /api {
#         proxy_pass http://127.0.0.1:8080;  # ou root + index.php via PHP-FPM
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#     }
# }
#
# # ── Ou Laravel en root directement ─────────────────────────
# server {
#     listen 443 ssl http2;
#     server_name noogo-e5ygx.ondigitalocean.app;
#     root /var/www/noogo/backend/public;
#     index index.php;
#
#     location / { try_files $uri $uri/ /index.php?$query_string; }
#     location ~ \.php$ {
#         fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
#         fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
#         include fastcgi_params;
#     }
#     location /dashboard {
#         alias /var/www/html/dashboard-noogo;
#         try_files $uri $uri/ /dashboard/index.html;
#     }
# }
