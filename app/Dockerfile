FROM php:8.0.12-fpm-buster as prepare

### PREPARATION PART of image ###
# should make any changes to it as less as possible
# only if need to install some liberty or php extension
ENV NGINX_VERSION=1.20.1 \
    NJS_VERSION=0.5.3 \
    PKG_RELEASE=1~buster \
    NODE_VERSION=14.18.1

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    curl \
    wget \
    bash \
    supervisor \
    git \
    dos2unix \
    openssh-client \
    # need for nginx and node
    # @see https://github.com/nodejs/docker-node/blob/3101ce6b5b3a0308b58d464eef141e0043c3bf5b/14/buster-slim/Dockerfile
    # @see https://github.com/nginxinc/docker-nginx/blob/f3fe494531f9b157d9c09ba509e412dace54cd4f/stable/debian/Dockerfile
    gnupg2 \
    ca-certificates \
    dirmngr \
    xz-utils \
    && rm -r /var/lib/apt/lists/* \
    # install nginx (copied from official nginx Dockerfile)
    && NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
        found=''; \
        for server in \
            ha.pool.sks-keyservers.net \
            hkp://keyserver.ubuntu.com:80 \
            hkp://p80.pool.sks-keyservers.net:80 \
            pgp.mit.edu \
        ; do \
            echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
            apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
        done; \

        test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
        rm -rf /var/lib/apt/lists/* \
        && dpkgArch="$(dpkg --print-architecture)" \
        && nginxPackages=" \
            nginx=${NGINX_VERSION}-${PKG_RELEASE} \
            nginx-module-xslt=${NGINX_VERSION}-${PKG_RELEASE} \
            nginx-module-geoip=${NGINX_VERSION}-${PKG_RELEASE} \
            nginx-module-image-filter=${NGINX_VERSION}-${PKG_RELEASE} \
            nginx-module-njs=${NGINX_VERSION}+${NJS_VERSION}-${PKG_RELEASE} \
        " \
        && echo "deb https://nginx.org/packages/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list \
        && apt-get update \
        && apt-get install --no-install-recommends --no-install-suggests -y \
            $nginxPackages \
            gettext-base \
            curl \
        # && apt-get remove --purge --auto-remove -y \
        && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list \
        # forward request and error logs to docker log collector
        && ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log \
    # install php extensions
    # using mlocati/docker-php-extension-installer recomended by official php docker repo
    # @see https://github.com/docker-library/docs/blob/master/php/README.md#php-core-extensions
    && curl -sSLf -o /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
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
        pcntl \
        imagick \
        # if install xdebug in `dev` stage there could be incompatibility with other php extensions
        xdebug \
## install node and yarn: copied from official node docker image
# LTS version of node
# gpg keys listed at https://github.com/nodejs/node#release-keys
    && set -ex \
    && for key in \
        4ED778F539E3634C779C87C6D7062848A1AB005C \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        74F12602B6F1C4E913FAA37AD3A89613643B6201 \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
        108F52B48DB57BB0CC439B2997B01419BD92F80A \
        B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    ; do \
        gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
        gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && apt-mark auto '.*' > /dev/null \
    && find /usr/local -type f -executable -exec ldd '{}' ';' \
        | awk '/=>/ { print $(NF-1) }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual \
    #&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version

# install composer from official image @see https://hub.docker.com/_/composer
COPY --from=composer:2.1.9 /usr/bin/composer /usr/bin/composer

### / PREPARATION PART of image ###



### Make base stage as production ###
FROM prepare as base

# add bitbucket and github to known hosts for ssh needs
WORKDIR /root/.ssh
RUN chmod 0600 /root/.ssh \
    && ssh-keyscan -t rsa bitbucket.org >> known_hosts \
    && ssh-keyscan -t rsa github.com >> known_hosts \
    && ssh-keyscan -t rsa gitlab.com >> known_hosts

# packages that will be used in a docker or in project via `exec()` php function @see https://www.php.net/manual/ru/function.exec.php
#RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
#    gettext-base \
#    dos2unix \
#    wget \
#    && rm -rf /var/lib/apt/lists/*

##
## Configuration of supervisord, php and nginx
##
# supervisord config
COPY ./docker/app/supervisord.conf /etc/supervisord.conf

# add custom php-fpm pool settings, these get written at entrypoint startup
ENV FPM_PM_MAX_CHILDREN=20 \
    FPM_PM_START_SERVERS=2 \
    FPM_PM_MIN_SPARE_SERVERS=1 \
    FPM_PM_MAX_SPARE_SERVERS=3 \
    FPM_PING_URI='/---ping' \
    FPM_STATUS_URI='/---status' \
    NGINX_STATUS_URI='/---status-nginx' \
    NGINX_READ_TIMEOUT=60

### php-fpm config ###
COPY ./docker/app/zzz-app.conf /tmp/zzz-app.conf
# name of the file is `zzz-app.conf`, so that the directive in /usr/local/etc/php-fpm.conf `include=etc/php-fpm.d/*.conf`
# would include zzz-app.conf file as the latest and according php-fpm configuration overwrite any previous config files
RUN envsubst '$FPM_PM_MAX_CHILDREN $FPM_PM_START_SERVERS $FPM_PM_MIN_SPARE_SERVERS $FPM_PM_MAX_SPARE_SERVERS $FPM_PING_URI $FPM_STATUS_URI' < /tmp/zzz-app.conf > /usr/local/etc/php-fpm.d/zzz-app.conf

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# custom php.ini
COPY ./docker/app/php-prod.ini /tmp/zzz-php.ini
# use `envsubst` library if need to generate config file bases on some environment (@see example below for php-dev.ini)
#RUN envsubst '$SOME_GLOBAL_ENV' < /tmp/zzz-php.ini > "$PHP_INI_DIR/conf.d/zzz-php.ini"

### nginx config ###
COPY ./docker/app/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/app/nginx-site.conf /tmp/nginx-site.conf
RUN mkdir -p /etc/nginx/conf.d \
    && envsubst '$FPM_PING_URI $FPM_STATUS_URI $NGINX_STATUS_URI $NGINX_READ_TIMEOUT' < /tmp/nginx-site.conf > /etc/nginx/conf.d/default.conf

ARG __PATH=$PATH

ENV COMPOSER_VENDOR_DIR="/var/www/html/vendor" \
    PATH="/var/www/html/node_modules/.bin:$__PATH"

### Decided to move `composer install` and `npm install` only to `test` and `prod` stages [but not on `dev`]
### Think it's more convenient for developer to execute
### docker-compose exec app bash
### and run according comands locally



### dev stage ###
FROM base as dev

WORKDIR /var/www/html

# Use development configuration (overwrite php.ini-production -- @see above)
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

ENV XDEBUG_TRIGGER='PHPSTORM'
# custom php.ini
COPY ./docker/app/php-dev.ini /tmp/zzz-php.ini
RUN envsubst '$XDEBUG_TRIGGER' < /tmp/zzz-php.ini > "$PHP_INI_DIR/conf.d/zzz-php.ini"

# in development we can install all dependencies to project root (more convinient for development, for example, debugging)
# compose install / npm install could be done developer manually after he do `docker-compose exec app bash`
ENV NODE_ENV="development"

# 80 - for nginx
# 9003 - for php debug
EXPOSE 80 9003

## no need in `dev` stage to run `COPY --chown=www-data:www-data . .` because in dev
## we will bind mount whole project (@see docker-compose.yml:services.app.volumes)

### copy entrypoint ###
COPY ./docker/app/docker-php-entrypoint-dev /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-php-entrypoint-dev \
    && chmod 770 /usr/local/bin/docker-php-entrypoint-dev

ENTRYPOINT ["docker-php-entrypoint-dev"]



### dependencies stage ###
# for running installing non-dev dependencies of composer and npm ###
FROM base as dependencies

# exclude packages from autoremove that are used @see https://askubuntu.com/a/943292
RUN apt-mark manual dos2unix supervisor wget openssh-client ca-certificates nginx
RUN apt-get remove --purge --auto-remove -y -o APT::AutoRemove::RecommendsImportant=false


### decided not to put dependencies in another dir (for now), because it would require to change accordingly ./public/index.php and ./artisan
WORKDIR /var/www/html

##
## Compose Package Manager
##
COPY --chown=www-data:www-data ./composer.json ./composer.lock* ./
# RUN composer config github-oauth.github.com YOUROAUTHKEYHERE
RUN composer install --no-scripts --no-autoloader --ansi --no-interaction --no-dev
##
## Node Build Tools
##
ENV NODE_ENV="production"
COPY --chown=www-data:www-data package*.json ./
RUN npm config list \
    # is better then `npm install` for production
    && npm ci || npm install
ENV PATH="/var/www/htmls/node_modules/.bin:$__PATH"



### test stage ###
FROM dependencies as test

WORKDIR /var/www/html

##
## Compose Package Manager
##
# RUN composer config github-oauth.github.com YOUROAUTHKEYHERE
# didn't found composer analogue for 'npm install --only=production'
RUN composer install --no-scripts --no-autoloader --ansi --no-interaction
RUN chown -R www-data:www-data /var/www/html/vendor
# temporary copy of all code (except for vendor and node_modules), so that we can copy it to /var/www/html (see below)
# remove those dependencies to not interfier any dev changes in those dirs
COPY --chown=www-data:www-data . /var/www/temp
RUN rm -rfv /var/www/temp/vendor \
    && rm -rfv /var/www/temp/node_modules \
    # @see https://askubuntu.com/a/86891
    && cp -a /var/www/temp/. /var/www/html/ \
    && rm -rfv /var/www/temp

##
## Node Build Tools
##
ENV NODE_ENV="development"
RUN npm config list \
    && npm install --only=development \
    && npm run prod \
    && npm cache clean --force

# https://docs.npmjs.com/cli/v7/commands/npm-audit
# RUN npm audit
# TODO think of security checker @see https://github.com/FriendsOfPHP/security-advisories
# TODO think of running `composer validate` or `composer outdated` or `composer diagnose`

RUN wget https://github.com/aquasecurity/trivy/releases/download/v0.20.2/trivy_0.20.2_Linux-64bit.deb
RUN dpkg -i trivy_0.20.2_Linux-64bit.deb \
    && trivy filesystem --exit-code 0 --no-progress /



### Pre production stage ###
## is used to not bloat prod image
## recomenned by Bret Fisher for avoiding put deleted unnecessary files in prod
FROM test as pre-prod

# delete unused in production files
# node_modules / css / js and images are compiled to ./public
RUN rm -rfv /var/www/html/tests \
    && rm -rfv /var/www/html/trivy_* \
    && rm -rfv /var/www/html/node_modules \
    && rm -rfv /var/www/html/resources/css \
    && rm -rfv /var/www/html/resources/js \
    # todo think if we need to remove non-persistent data manually
    && rm -rfv /var/www/html/bootstrap/cache/data/* \
    && rm -rfv /var/www/html/storage/logs/* \
    && rm -rfv /var/www/html/storage/framework/sessions/* \
    && rm -rfv /var/www/html/storage/framework/views/* \
    && rm -rfv /var/www/html/storage/framework/testing/*



### Prod stage ###
FROM dependencies as prod

### copy entrypoint and overwrite default one of base php image ###
COPY ./docker/app/docker-php-entrypoint-prod /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-php-entrypoint-prod \
    && chmod 770 /usr/local/bin/docker-php-entrypoint-prod

ENTRYPOINT ["docker-php-entrypoint-prod"]

# we already have node_modules / tests / resources/(css|js) / storage in base
# so we copy from pre-prod without those of 'test' stage
COPY --from=pre-prod --chown=www-data:www-data /var/www/html /var/www/html

# be sure nginx is properly passing to php-fpm and fpm is responding
HEALTHCHECK --interval=5s --timeout=3s CMD curl -f "http://localhost$FPM_PING_URI" || exit 1

# 80 - for nginx
EXPOSE 80

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]


# TODO think of adding base auth for $FPM_PING_URI $FPM_STATUS_URI $NGINX_STATUS_URI pages
#RUN /bin/bash -c "htpasswd -bn default secret > /etc/nginx/conf.d/nginx.htpasswd"
#COPY ./docker/app/nginx.htpasswd /etc/nginx/conf.d/nginx.htpasswd
