### Make base stage as production ###
# vasymus/base-php-nginx-node:php-7.4.27-nginx-1.20.1-node-14.18.1 -- temporary decision
FROM vasymus/base-php-nginx-node:php-8.0.15-nginx-1.20.1-node-16.13.2 as base

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

# Dockerfile private variable -- not for build
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

# for running some scripts as www-data inside container
RUN apt-get update && apt-get install -y sudo



### dependencies stage ###
# for running installing non-dev dependencies of composer and npm ###
FROM base as dependencies

# exclude packages from autoremove that are used @see https://askubuntu.com/a/943292
#RUN apt-mark manual dos2unix supervisor wget openssh-client ca-certificates nginx
#RUN apt-get remove --purge --auto-remove -y -o APT::AutoRemove::RecommendsImportant=false

# in laravel `env()` function take environemt variables from .env file or from OS global environment
# in production we put all environments to OS global environment
# in dev we assume that developer manually create .env file (based on .env.example)
ENV APP_NAME="Lara 8 src" \
    APP_ENV="production" \
    # temporary key for building only. Real key should be pass via docker secret or other hidden way
    APP_KEY="base64:rLuN5t3YwZvIyOn+/I3AHD2nJbYIUcVXHq+PqJH5IZ8=" \
    APP_DEBUG="false" \
    APP_URL="http://localhost" \
    # errors in docker should go to stdout (not in file, because the file could consume all space on disk)
    LOG_CHANNEL="errorlog" \
    LOG_LEVEL="debug" \
    DB_CONNECTION="mysql" \
    DB_HOST="db" \
    DB_PORT=3306 \
    DB_DATABASE="laravel" \
    DB_USERNAME="default" \
    DB_PASSWORD="secret" \
    BROADCAST_DRIVER="log" \
    CACHE_DRIVER="array" \
    FILESYSTEM_DRIVER="local" \
    QUEUE_CONNECTION="sync" \
    SESSION_DRIVER="file" \
    SESSION_LIFETIME=120 \
    MAIL_MAILER="smtp" \
    MAIL_HOST="mailhog" \
    MAIL_PORT=1025 \
    MAIL_USERNAME=null \
    MAIL_PASSWORD=null \
    MAIL_ENCRYPTION=null \
    MAIL_FROM_ADDRESS=null \
    MAIL_FROM_NAME="${APP_NAME}"

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
    && rm -rfv /var/www/html/resources/images \
    && rm -rfv /var/www/html/resources/fonts \
    # todo think if we need to remove non-persistent data manually
    && rm -rfv /var/www/html/bootstrap/cache/data/* \
    && rm -rfv /var/www/html/storage/logs/* \
    && rm -rfv /var/www/html/storage/media-library/temp/* \
    && rm -rfv /var/www/html/storage/debugbar/* \
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
