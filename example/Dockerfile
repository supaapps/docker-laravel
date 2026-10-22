# syntax=docker/dockerfile:1
FROM ghcr.io/supaapps/docker-laravel:php8.4-build-20261022.1@sha256:3d649a08e4f5a5e177c30c9a1914428ca5543ac88c5959a5fce7f4c0b4dba1cf AS build
WORKDIR /var/www
COPY . .
RUN --mount=type=secret,id=composer_auth,target=/tmp/composer/auth.json COMPOSER_HOME=/tmp/composer composer install --no-plugins --no-scripts --no-dev --no-interaction --prefer-dist --optimize-autoloader
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

FROM build AS test
RUN --mount=type=secret,id=composer_auth,target=/tmp/composer/auth.json COMPOSER_HOME=/tmp/composer composer install --no-plugins --no-scripts --no-interaction --prefer-dist

FROM ghcr.io/supaapps/docker-laravel:php8.4-runtime-20261022.1@sha256:aa6eb4356ee9aa0ba819ecdba20b43ae3b35d1668dc250a58a3dc9a8c0668398 AS runtime
WORKDIR /var/www
COPY --from=build /var/www/ /var/www/
COPY --chmod=0755 docker/startup.sh /docker/startup.sh
EXPOSE 80
ENTRYPOINT ["/docker/startup.sh"]
