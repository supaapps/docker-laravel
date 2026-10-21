ARG PHP_BASE_IMAGE=php:8.4.27-apache-bookworm@sha256:e4fb8001898613d5d0d00eabbae33b9c30b050698b522f15d864bb0bac916945
FROM composer:2.10.3@sha256:d0c32820c62cc860fddd22adceed4eeda7698b093a7a88d503414172ce400626 AS composer
FROM ${PHP_BASE_IMAGE}

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# INSTALL SERVER DEPENDENCIES -------- #
RUN apt-get update && apt-get install -y libmcrypt-dev \
    libmagickwand-dev git zip unzip cron libzip-dev libpq-dev --no-install-recommends \
    && pecl install imagick-3.8.1 \
    && pecl install xdebug-3.5.3 \
    && pecl install redis-6.3.0 \
    && docker-php-ext-enable imagick xdebug redis\
    && docker-php-ext-install zip pdo_mysql pdo_pgsql mysqli gd sockets \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/pear \
    && mv /var/www/html /var/www/public

# POINT APACHE TO PUBLIC DIRECTORY --- #
RUN sed -ri -e 's!/var/www/html!/var/www/public!g' /etc/apache2/sites-available/000-default.conf
RUN sed -ri -e 's!/var/www/!/var/www/public!g' /etc/apache2/conf-available/*.conf

RUN printf ' \n\
    <Directory /var/www/public>\n\
        Options FollowSymLinks\n\
        AllowOverride All\n\
        Order allow,deny\n\
        Allow from all\n\
    </Directory>\n\
    ' >> /etc/apache2/sites-available/000-default.conf

# CHANGE DEFAULT PHP CONFIG ---------- #
RUN printf ' \n\
file_uploads = On\n\
memory_limit = 128M\n\
upload_max_filesize = 100M\n\
post_max_size = 100M\n\
max_execution_time = 600\n\
variables_order = EGPCS\n\
display_errors = Off\n\
display_startup_errors = Off\n\
session.upload_progress.enabled = Off\n\
' > /usr/local/etc/php/conf.d/docker-custom.ini

RUN a2enmod rewrite

# INSTALL COMPOSER ------------------- #
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www

# ADD LARAVEL SCHEDULE TO CRON ------- #
# THIS ONLY WORKS FOR ENTRY POINT RUNNING CRONTAB, no background tasks will 
# RUN echo "* * * * * root php /var/www/artisan schedule:run  > /proc/1/fd/1 2>/proc/1/fd/2"  >> /etc/crontab

EXPOSE 80
