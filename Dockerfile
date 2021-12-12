FROM php:8.0-apache


ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y libmcrypt-dev \
    libmagickwand-dev git zip unzip libzip-dev --no-install-recommends \
    && pecl install imagick \
    && pecl install xdebug \
    && pecl install redis \
    && docker-php-ext-enable imagick xdebug redis\
    && docker-php-ext-install zip pdo_mysql mysqli gd sockets \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*



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

RUN printf ' \n\
file_uploads = On\n\
memory_limit = 128M\n\
upload_max_filesize = 100M\n\
post_max_size = 100M\n\
max_execution_time = 600\n\
variables_order = EGPCS\n\
' > /usr/local/etc/php/conf.d/docker-custom.ini

RUN a2enmod rewrite


EXPOSE 80
