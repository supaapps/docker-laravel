FROM local/base-image:test
RUN docker-php-ext-install bcmath \
    && php -r 'if (!extension_loaded("bcmath") || bcadd("1.5", "2.5", 1) !== "4.0") { throw new RuntimeException("Downstream extension build failed"); }'
