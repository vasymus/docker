# Multistage dockerfile
# always pin the version
FROM php:8.0.11-fpm as base

# nginx env (copied from official nginx dockerfile)
# @see https://github.com/nginxinc/docker-nginx/blob/f3fe494531f9b157d9c09ba509e412dace54cd4f/stable/debian/Dockerfile
ENV NGINX_VERSION=1.20.1 \
    PKG_RELEASE=1~buster \
    NJS_VERSION=0.5.3 \
# node env (copied from official node dockerfile)
# @see https://github.com/nodejs/docker-node/blob/a70c43d47528213ef0cd58af7c35edf4c1d3e990/14/buster-slim/Dockerfile
    NODE_VERSION=14.18.1 \
# general env
    APP_DIR="/var/www/html"

# install apt dependencies
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
        wget \
        curl \
        bash \
        supervisor \
        git && \
        rm -r /var/lib/apt/lists/* && \
# install php extensions
# using mlocati/docker-php-extension-installer recomended by official php docker repo
# @see https://github.com/docker-library/docs/blob/master/php/README.md#php-core-extensions
    curl -sSLf \
        -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        install-php-extensions \
            pdo_mysql \
            mysqli \
            json \
            gd \
            intl \
            mbstring \
            redis \
            sockets \
            zip \
            xml \
            exif \
            bcmath \
            pcntl




FROM base as dev
## TODO think of adding yarn
## add xdebug
# install-php-extensions xdebug






# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Optional, force UTC as server time
RUN echo "UTC" > /etc/timezone







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


# Clean up
RUN apt-get remove -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR $APP_DIR


ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

EXPOSE 9000
