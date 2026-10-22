# syntax=docker/dockerfile:1
FROM ghcr.io/supaapps/docker-laravel:php8.2-build-20261022.1@sha256:91d9a31546a8bc71e28f7a8a23570d3d188297a1eb54d1486f3f379371dab8af AS build
WORKDIR /var/www
COPY . .
RUN --mount=type=secret,id=composer_auth,target=/tmp/composer/auth.json COMPOSER_HOME=/tmp/composer composer install --no-plugins --no-scripts --no-dev --no-interaction --prefer-dist --optimize-autoloader
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

FROM build AS test
RUN --mount=type=secret,id=composer_auth,target=/tmp/composer/auth.json COMPOSER_HOME=/tmp/composer composer install --no-plugins --no-scripts --no-interaction --prefer-dist

FROM ghcr.io/supaapps/docker-laravel:php8.2-runtime-20261022.1@sha256:400474e8bdc551fb5aa306d24f622857a571e565ce600ef9863075d91edb5287 AS runtime
WORKDIR /var/www
COPY --from=build /var/www/ /var/www/
COPY --chmod=0755 docker/startup.sh /docker/startup.sh
EXPOSE 80
ENTRYPOINT ["/docker/startup.sh"]
