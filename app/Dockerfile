FROM php:7.2.34-fpm

# make sure apt is up to date
RUN apt-get update --fix-missing

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    bash \
    supervisor \
    npm \
    git \
    yarn

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Optional, force UTC as server time
RUN echo "UTC" > /etc/timezone

# pdo_mysql
RUN docker-php-ext-install pdo_mysql

# Setup GD extension
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6 \
    libfreetype6-dev \
    libjpeg-turbo-progs \
    libpng16-16 \
    libpng-dev

RUN docker-php-ext-configure gd \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-enable gd \
    && rm -rf /tmp/*

# Install intl extension
RUN apt-get update && apt-get install -y \
    libicu-dev \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-enable intl \
    && rm -rf /tmp/*

# Install mbstring extension
RUN apt-get update && apt-get install -y \
    libonig-dev \
    && docker-php-ext-install mbstring \
    && docker-php-ext-enable mbstring \
    && rm -rf /tmp/*

# redis
RUN pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/pear

# sockets
RUN docker-php-ext-install sockets

# zip
RUN apt-get update && apt-get install -y \
    libzip-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip

# xml
RUN apt-get update && apt-get install -y libxml2-dev
RUN docker-php-ext-install xml

# exif
RUN docker-php-ext-install exif

# bcmath
RUN docker-php-ext-install bcmath

# pcntl
RUN docker-php-ext-install pcntl

# mysqli
RUN docker-php-ext-install mysqli

WORKDIR /etc

COPY supervisord.conf /etc/supervisord.conf

# Clean up
RUN apt-get remove -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html

#RUN mkdir /var/www/html/bootstrap
#RUN mkdir /var/www/html/bootstrap/cache
#RUN mkdir /var/www/html/storage
#RUN chown -R www-data:www-data /var/www/html/bootstrap/cache
#RUN chown -R www-data:www-data /var/www/html/storage

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

EXPOSE 9000
