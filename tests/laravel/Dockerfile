ARG TEST_IMAGE=local/base-image:test
FROM composer:2.10.3@sha256:d0c32820c62cc860fddd22adceed4eeda7698b093a7a88d503414172ce400626 AS composer
FROM ${TEST_IMAGE} AS fixture
ARG LARAVEL_VERSION=^12.0
COPY --from=composer /usr/bin/composer /tmp/composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN php /tmp/composer create-project --no-plugins --no-scripts --no-dev --prefer-dist \
      --no-interaction laravel/laravel /tmp/laravel "${LARAVEL_VERSION}" \
    && cd /tmp/laravel \
    && cp .env.example .env \
    && php artisan key:generate --force \
    && php artisan package:discover --ansi \
    && php artisan about --only=environment \
    && php artisan route:list \
    && chmod -R a+rwX storage bootstrap/cache

# Test the application on the unchanged target, without the temporary installer.
FROM ${TEST_IMAGE}
COPY --from=fixture /tmp/laravel /var/www
