FROM php:8.3-cli

# ── Dépendances système ───────────────────────────────────────
RUN apt-get update && apt-get install -y \
    git curl libzip-dev zip unzip \
    libpng-dev libonig-dev libxml2-dev \
    libpq-dev \
    && docker-php-ext-install \
    pdo pdo_mysql pdo_pgsql \
    mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Composer ─────────────────────────────────────────────────
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# ── Dépendances PHP (séparé pour le cache Docker) ────────────
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# ── Code source ───────────────────────────────────────────────
COPY . .

# ── Post-install scripts ──────────────────────────────────────
RUN composer run-script post-autoload-dump

# ── Permissions ───────────────────────────────────────────────
RUN mkdir -p storage/logs storage/framework/cache \
    storage/framework/sessions storage/framework/views \
    bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# ── Port exposé (Render injecte $PORT=10000 par défaut) ──────
EXPOSE 10000

# ── Démarrage ─────────────────────────────────────────────────
CMD ["/bin/sh", "start.sh"]
