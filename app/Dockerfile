# Multistage dockerfile
# always pin the version
FROM php:8.0.11-fpm as base

ENV NGINX_VERSION=1.20.1 \
    PKG_RELEASE=1~buster \
    NJS_VERSION=0.5.3 \
    NODE_VERSION=14.18.1

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    wget \
    curl \
    bash \
    supervisor \
    npm \
    git \
    yarn




FROM base as dev
## TODO think of adding yarn


# install https://github.com/mlocati/docker-php-extension-installer for more convenient installation of php extension
# this docker image (mlocati/docker-php-extension-installer) is recommended by official php docker repo
# @see https://github.com/docker-library/docs/blob/master/php/README.md#php-core-extensions
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/


RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions gd xdebug

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

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
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
# alternative to install specific version -- didn't found a way to install specific version using docker-php-ext-install
# pecl install Zip-1.20.0
# apt-get update && apt-get install libzip-dev=1.5*
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

# node
ENV NODE_VERSION=14.17.6
RUN apt install -y curl
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

WORKDIR /etc

COPY supervisord.conf /etc/supervisord.conf

RUN apt-get update && apt-get install -y procps

# Clean up
RUN apt-get remove -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG APP_DIR="/var/www/html"
WORKDIR $APP_DIR

#RUN mkdir /var/www/html/bootstrap
#RUN mkdir /var/www/html/bootstrap/cache
#RUN mkdir /var/www/html/storage
#RUN chown -R www-data:www-data /var/www/html/bootstrap/cache
#RUN chown -R www-data:www-data /var/www/html/storage

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

EXPOSE 9000
