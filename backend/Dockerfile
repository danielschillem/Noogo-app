# ============================================================
# Image serversideup/php — PHP 8.3 + FPM + Nginx
# Optimisée pour Laravel en production
# Docs : https://serversideup.net/open-source/docker-php/
# ============================================================
FROM serversideup/php:8.4-fpm-nginx

# Passer en root pour installer les dépendances
USER root

# ── Extensions supplémentaires (pgsql, redis optionnel) ──────
RUN install-php-extensions pdo_pgsql pdo_mysql

# ── Composer ─────────────────────────────────────────────────
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ── Dépendances PHP ──────────────────────────────────────────
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# ── Code source ──────────────────────────────────────────────
COPY . .

# ── Post-install ─────────────────────────────────────────────
RUN composer run-script post-autoload-dump 2>/dev/null || true

# ── Permissions Laravel ──────────────────────────────────────
RUN mkdir -p storage/logs storage/framework/cache \
    storage/framework/sessions storage/framework/views \
    bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# ── Configuration Nginx principale ──────────────────────────
# On fournit notre propre nginx.conf (serversideup ne l'inclut pas toujours)
COPY nginx.conf /etc/nginx/nginx.conf

# ── Script de démarrage ──────────────────────────────────────
COPY start.sh /start-noogo.sh
RUN chmod +x /start-noogo.sh

# Le port 8080 est le défaut de serversideup (Nginx interne)
EXPOSE 8080

CMD ["/start-noogo.sh"]
