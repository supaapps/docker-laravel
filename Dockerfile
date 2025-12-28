FROM php:8.4-apache

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# INSTALL SERVER DEPENDENCIES -------- #
RUN apt-get update && apt-get install -y libmcrypt-dev \
    libmagickwand-dev git zip unzip cron libzip-dev libpq-dev --no-install-recommends \
    && pecl install imagick \
    && pecl install xdebug \
    && pecl install redis \
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
' > /usr/local/etc/php/conf.d/docker-custom.ini

RUN a2enmod rewrite

# INSTALL COMPOSER ------------------- #
RUN curl --silent --show-error https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN chmod a+x /usr/local/bin/composer

WORKDIR /var/www

# ADD LARAVEL SCHEDULE TO CRON ------- #
# THIS ONLY WORKS FOR ENTRY POINT RUNNING CRONTAB, no background tasks will 
# RUN echo "* * * * * root php /var/www/artisan schedule:run  > /proc/1/fd/1 2>/proc/1/fd/2"  >> /etc/crontab

EXPOSE 80
