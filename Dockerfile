# =============================================================
# Noogo — Dockerfile DigitalOcean
# Build multi-stage : React dashboard (Node) + Laravel (PHP-FPM) + Nginx
# Un seul conteneur sert le dashboard React et l'API Laravel
# =============================================================

# ─── Stage 1 : Build du dashboard React ─────────────────────
FROM node:20-alpine AS dashboard-builder

WORKDIR /app

COPY dashboard/package*.json ./
RUN npm ci --prefer-offline

COPY dashboard/ ./

# Variables Vite baked-in au build (même origin → URLs relatives)
ARG VITE_API_URL=/api
ARG VITE_IMAGE_BASE_URL=
ARG VITE_PUSHER_KEY=
ARG VITE_PUSHER_CLUSTER=eu

ENV VITE_API_URL=$VITE_API_URL \
    VITE_IMAGE_BASE_URL=$VITE_IMAGE_BASE_URL \
    VITE_PUSHER_KEY=$VITE_PUSHER_KEY \
    VITE_PUSHER_CLUSTER=$VITE_PUSHER_CLUSTER

RUN npm run build

# ─── Stage 2 : Backend PHP-FPM + Nginx ──────────────────────
FROM php:8.4-fpm-alpine

# Packages système
RUN apk add --no-cache \
    nginx \
    postgresql-dev \
    libpng-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    zip unzip curl bash

# Extensions PHP requises par Laravel
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo pdo_pgsql pdo_mysql gd zip opcache bcmath pcntl

# OPcache (production)
RUN { \
    echo "opcache.enable=1"; \
    echo "opcache.memory_consumption=128"; \
    echo "opcache.max_accelerated_files=10000"; \
    echo "opcache.revalidate_freq=0"; \
    echo "opcache.validate_timestamps=0"; \
    echo "opcache.interned_strings_buffer=8"; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# php.ini production
RUN { \
    echo "upload_max_filesize=100M"; \
    echo "post_max_size=100M"; \
    echo "memory_limit=256M"; \
    echo "max_execution_time=60"; \
    echo "expose_php=Off"; \
    } > /usr/local/etc/php/conf.d/noogo.ini

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Dépendances PHP (couche séparée pour le cache de build)
COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Code source Laravel
COPY backend/ .

# Regénérer l'autoloader avec toutes les classes (seeders, etc.)
# --no-scripts évite "artisan package:discover" qui nécessite APP_KEY
# package:discover est exécuté au démarrage via entrypoint.do.sh (config:cache)
RUN composer dump-autoload --optimize --no-dev --no-interaction --no-scripts

# Dashboard React (fichiers statiques servis par Nginx)
COPY --from=dashboard-builder /app/dist ./public/dashboard

# Permissions Laravel + symlink public/storage (sans artisan - pas d'APP_KEY au build)
RUN mkdir -p storage/logs storage/framework/cache \
    storage/framework/sessions storage/framework/views \
    storage/app/public \
    bootstrap/cache \
    && ln -sf /var/www/html/storage/app/public /var/www/html/public/storage \
    && chown -R www-data:www-data storage bootstrap/cache public/dashboard \
    && chmod -R 775 storage bootstrap/cache

# Configurations
COPY nginx.do.conf /etc/nginx/nginx.conf

# Script de démarrage
COPY entrypoint.do.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
