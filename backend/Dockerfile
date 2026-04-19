# ============================================================
# Image serversideup/php — PHP 8.4 + FPM + Nginx
# Optimisée pour Laravel en production
# Docs : https://serversideup.net/open-source/docker-php/
# ============================================================
FROM serversideup/php:8.4-fpm-nginx

# Passer en root pour installer les dépendances
USER root

# -- Extensions supplémentaires --------------------------------
RUN install-php-extensions pdo_pgsql pdo_mysql fileinfo

# -- Composer -------------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# -- Dépendances PHP ------------------------------------------
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

# -- AUTORUN serversideup --------------------------------------
# Nginx + PHP-FPM demarrent EN PREMIER via s6-overlay,
# puis les autorun s executent en arriere-plan.
# Cela garantit que Railway peut faire son healthcheck des le demarrage.
ENV AUTORUN_ENABLED=true \
    AUTORUN_LARAVEL_MIGRATION=true \
    AUTORUN_LARAVEL_CONFIG_CACHE=true \
    AUTORUN_LARAVEL_ROUTE_CACHE=true \
    AUTORUN_LARAVEL_VIEW_CACHE=true \
    AUTORUN_LARAVEL_STORAGE_LINK=true

# -- Port -----------------------------------------------------
# Railway injecte PORT dynamiquement.
# L entrypoint.d mappe PORT -> NGINX_HTTP_PORT avant que s6 genere nginx.conf.
ENV NGINX_HTTP_PORT=8080

# -- Entrypoint personnalise : APP_KEY + PORT -> NGINX_HTTP_PORT --
COPY docker/entrypoint.d/00-noogo-setup.sh /etc/entrypoint.d/00-noogo-setup.sh
RUN chmod +x /etc/entrypoint.d/00-noogo-setup.sh

# -- Seeder admin via s6 oneshot (apres AUTORUN migrations) ---
COPY docker/s6/noogo-seed/type /etc/s6-overlay/s6-rc.d/noogo-seed/type
COPY docker/s6/noogo-seed/up /etc/s6-overlay/s6-rc.d/noogo-seed/up
RUN chmod +x /etc/s6-overlay/s6-rc.d/noogo-seed/up && \
    mkdir -p /etc/s6-overlay/s6-rc.d/noogo-seed/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/noogo-seed/dependencies.d/laravel-automations && \
    mkdir -p /etc/s6-overlay/user/contents.d && \
    touch /etc/s6-overlay/user/contents.d/noogo-seed

EXPOSE 8080
