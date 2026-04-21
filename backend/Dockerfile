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
# Storage link + optimizations run in entrypoint (no DB needed).
# Migrations are handled by our s6 oneshot service (noogo-db-init)
# which runs AFTER Nginx is up, avoiding Render port-detection timeout.
ENV AUTORUN_ENABLED=true \
    AUTORUN_LARAVEL_MIGRATION=false \
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

# -- s6 oneshot : migrations + seed APRÈS Nginx (évite timeout Render) --
COPY docker/s6/noogo-db-init/type /etc/s6-overlay/s6-rc.d/noogo-db-init/type
COPY docker/s6/noogo-db-init/up /etc/s6-overlay/s6-rc.d/noogo-db-init/up
COPY docker/s6/noogo-db-init/dependencies.d/nginx /etc/s6-overlay/s6-rc.d/noogo-db-init/dependencies.d/nginx
COPY docker/s6/scripts/noogo-db-init /etc/s6-overlay/scripts/noogo-db-init
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/noogo-db-init \
    && chmod +x /etc/s6-overlay/scripts/noogo-db-init

EXPOSE 10000
