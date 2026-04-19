# ============================================================
# Image serversideup/php � PHP 8.4 + FPM + Nginx
# Optimis�e pour Laravel en production
# Docs : https://serversideup.net/open-source/docker-php/
# ============================================================
FROM serversideup/php:8.4-fpm-nginx

# Passer en root pour installer les d�pendances
USER root

# -- Extensions suppl�mentaires --------------------------------
RUN install-php-extensions pdo_pgsql pdo_mysql fileinfo

# -- Composer -------------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# -- D�pendances PHP ------------------------------------------
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# -- Code source ----------------------------------------------
COPY . .

# -- Post-install ---------------------------------------------
RUN composer run-script post-autoload-dump 2>/dev/null || true

# -- Permissions Laravel --------------------------------------
RUN mkdir -p storage/logs storage/framework/cache \
    storage/framework/sessions storage/framework/views \
    bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# -- OPcache (PRODUCTION) --------------------------------------
ENV PHP_OPCACHE_ENABLE=1

# -- AUTORUN serversideup --------------------------------------
# Nginx + PHP-FPM demarrent EN PREMIER via s6-overlay,
# puis les autorun s executent en arriere-plan.
ENV AUTORUN_ENABLED=true \
    AUTORUN_LARAVEL_MIGRATION=true \
    AUTORUN_LARAVEL_CONFIG_CACHE=true \
    AUTORUN_LARAVEL_ROUTE_CACHE=true \
    AUTORUN_LARAVEL_VIEW_CACHE=true \
    AUTORUN_LARAVEL_STORAGE_LINK=true

# -- Port -----------------------------------------------------
# Render injecte PORT dynamiquement (defaut 10000).
# L entrypoint.d mappe PORT -> NGINX_HTTP_PORT avant que s6 genere nginx.conf.
ENV NGINX_HTTP_PORT=10000

# -- Entrypoint personnalise : APP_KEY + .env + PORT -> NGINX_HTTP_PORT --
COPY docker/entrypoint.d/00-noogo-setup.sh /etc/entrypoint.d/00-noogo-setup.sh
RUN chmod +x /etc/entrypoint.d/00-noogo-setup.sh

EXPOSE 10000
