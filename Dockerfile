FROM webdevops/php-nginx:8.2-alpine

# Configuración del entorno
RUN set -eux; \
    sed -i 's|dl-cdn.alpinelinux.org|dl-4.alpinelinux.org|g' /etc/apk/repositories; \
    apk update && apk add --no-cache \
    oniguruma-dev \
    postgresql-dev \
    libxml2-dev \
    nodejs \
    npm; \
    npm install --global yarn

# Copiar Composer desde la imagen oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Definir variables de entorno
ENV WEB_DOCUMENT_ROOT /app/public
WORKDIR /app

# Copiar los archivos de la aplicación al contenedor
COPY ./laravel-app/ /app/

# Instalar dependencias de Laravel y frontend
RUN composer install --no-interaction --optimize-autoloader; \
    npm install; \
    yarn install; \
    yarn build; \
    php artisan config:clear; \
    php artisan cache:clear; \
    php artisan storage:link

# Cambiar permisos
RUN chown -R application:application /app

# Precompilar vistas, rutas y configuraciones para producción
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache