#!/bin/bash

if [ -d "/var/www/public" ]
then
    chmod -R 777 /var/www/storage
    composer install --no-ansi --no-suggest --no-interaction --no-scripts
    php /var/www/artisan migrate --force
else
    mkdir -p "/var/www/public"
    echo "error :/" >> "/var/www/public/index.php"
fi

apache2-foreground