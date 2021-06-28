FROM php:7.4.16-fpm-alpine3.13

RUN apk --update add --no-cache wget \
    curl \
    bash \
    supervisor \
    npm \
    composer \
    git \
    yarn

# Optional, force UTC as server time
RUN echo "UTC" > /etc/timezone

# pdo_mysql
RUN docker-php-ext-install pdo_mysql

# Setup GD extension
RUN apk add --no-cache \
      freetype \
      libjpeg-turbo \
      libpng \
      freetype-dev \
      libjpeg-turbo-dev \
      libpng-dev \
    && docker-php-ext-configure gd \
      --with-freetype=/usr/include/ \
      # --with-png=/usr/include/ \ # No longer necessary as of 7.4; https://github.com/docker-library/php/pull/910#issuecomment-559383597
      --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-enable gd \
    && apk del --no-cache \
      freetype-dev \
      libjpeg-turbo-dev \
      libpng-dev \
    && rm -rf /tmp/*

# Install intl extension
RUN apk add --no-cache \
    icu-dev \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-enable intl \
    && rm -rf /tmp/*

# Install mbstring extension
RUN apk add --no-cache \
    oniguruma-dev \
    && docker-php-ext-install mbstring \
    && docker-php-ext-enable mbstring \
    && rm -rf /tmp/*

# redis
RUN apk --update add autoconf g++ make
RUN pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

# sockets
RUN docker-php-ext-install sockets

# zip
RUN apk --update add libzip-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip

# xml
RUN apk --update add libxml2-dev
RUN docker-php-ext-install xml

# exif
RUN docker-php-ext-install exif

# bcmath
RUN docker-php-ext-install bcmath

# pcntl
RUN docker-php-ext-install pcntl


WORKDIR /etc

COPY supervisord.conf /etc/supervisord.conf

# Clean up
RUN rm /var/cache/apk/*

WORKDIR /var/www/html

RUN mkdir /var/www/html/bootstrap
RUN mkdir /var/www/html/bootstrap/cache
RUN mkdir /var/www/html/storage
RUN chown -R www-data:www-data /var/www/html/bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

EXPOSE 9000
