FROM webdevops/php-nginx:8.2-alpine

# Install Laravel framework system requirements (https://laravel.com/docs/8.x/deployment#optimizing-configuration-loading)
RUN  set -eux; \ 
     apk update && apk add oniguruma-dev postgresql-dev libxml2-dev nodejs npm ;\
     npm install --global yarn

# Copy Composer binary from the Composer official Docker image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ENV WEB_DOCUMENT_ROOT /app/public
WORKDIR /app
COPY ./laravel-app .

RUN composer install --no-interaction --optimize-autoloader --no-dev; \
    npm install; \
    yarn install; \
    yarn build ; \
    php artisan storage:link
RUN php artisan cache:clear
RUN php artisan config:clear

# Optimizing Configuration loading
RUN php artisan config:cache
# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache 


RUN chown -R application:application .