#!/bin/sh
set -eu
cd /var/www
php artisan migrate --force
exec apache2-foreground
