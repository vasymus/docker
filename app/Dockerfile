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
RUN envsubst '$SOME_GLOBAL_ENV' < /tmp/zzz-php.ini > "$PHP_INI_DIR/conf.d/zzz-php.ini"

### nginx config ###
COPY ./docker/app/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/app/nginx-site.conf /tmp/nginx-site.conf
RUN mkdir -p /etc/nginx/conf.d \
    && envsubst '$FPM_PING_URI $FPM_STATUS_URI $NGINX_STATUS_URI $NGINX_READ_TIMEOUT' < /tmp/nginx-site.conf > /etc/nginx/conf.d/default.conf

### Decided to move `composer install` and `npm install` only to `test` and `prod` stages [but not on `dev`]
### Think it's more convenient for developer to execute
### docker-compose exec app bash
### and run according comands locally



### dev stage ###
FROM base as dev

WORKDIR /var/www/html

# Use development configuration (overwrite php.ini-production -- @see above)
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# custom php.ini
COPY ./docker/app/php-dev.ini /tmp/zzz-php.ini
# use `envsubst` library if need to generate config file bases on some environment (@see example below for php-dev.ini)
RUN envsubst '$SOME_GLOBAL_ENV' < /tmp/zzz-php.ini > "$PHP_INI_DIR/conf.d/zzz-php.ini"

ARG XDEBUG_TRIGGER='PHPSTORM'
ARG XDEBUG_ON=false
COPY ./docker/app/php-xdebug.ini /tmp/zz-xdebug.ini

RUN if [ ${XDEBUG_ON} = true ]; then \
    envsubst '$XDEBUG_TRIGGER' < /tmp/zz-xdebug.ini > "$PHP_INI_DIR/conf.d/zz-xdebug.ini" \
;fi

# in development we can install all dependencies to project root (more convinient for development, for example, debugging)
# compose install / npm install could be done developer manually after running `docker-compose exec app bash`
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



### dependencies stage ###
# for running installing non-dev dependencies of composer and npm ###
FROM base as dependencies

WORKDIR /var/www/html

# copy seeds separately for image cache
COPY --chown=www-data:www-data ./storage ./storage

##
## Compose Package Manager
##
COPY --chown=www-data:www-data ./composer.json ./composer.lock* ./
# RUN composer config github-oauth.github.com YOUROAUTHKEYHERE
# for some reason if you run on hosting with flag doctrine is not install
RUN composer install --no-scripts --no-autoloader --ansi --no-interaction

##
## Npm Install And Node Build Tools (webpack)
##
ENV NODE_ENV="development"
COPY --chown=www-data:www-data ./package*.json ./
COPY --chown=www-data:www-data ./resources/js/vendor ./resources/js/vendor
RUN npm config list \
    # is better then `npm install` for production
    && npm ci || npm install

COPY --chown=www-data:www-data ./webpack.mix.js ./
COPY --chown=www-data:www-data ./webpack.config.js ./
COPY --chown=www-data:www-data ./webpack.ssr.mix.js ./
COPY --chown=www-data:www-data ./tsconfig.json ./
# didn't find to copy (without resources/view folder) in one COPY command without changing directory structure
# https://stackoverflow.com/a/37715522
COPY --chown=www-data:www-data ./resources/fonts ./resources/fonts
COPY --chown=www-data:www-data ./resources/images ./resources/images
COPY --chown=www-data:www-data ./resources/js ./resources/js
COPY --chown=www-data:www-data ./resources/sass ./resources/sass

##
## Copy Other Files
##
# didn't find a way to copy ./ ./ without ./storage, which was copies earlier @see https://github.com/moby/moby/issues/15771
COPY --chown=www-data:www-data ["./artisan", "./server.php", "./"]
COPY --chown=www-data:www-data ./bootstrap ./bootstrap
COPY --chown=www-data:www-data ./config ./config
COPY --chown=www-data:www-data ./database ./database
COPY --chown=www-data:www-data ./public ./public
COPY --chown=www-data:www-data ./resources/views ./resources/views
COPY --chown=www-data:www-data ./routes ./routes
COPY --chown=www-data:www-data ./src ./src

##
## Run build of ziggy routes and frontend scaffolding
##
RUN composer ziggy-routes
RUN npm run prod



##
## Delete Files That Are Not Used In Production
##
# node_modules / css / js and images are compiled to ./public
RUN rm -rfv /var/www/html/tests \
    && rm -rfv /var/www/html/node_modules \
    && rm -rfv /var/www/html/node_modules \
    && rm -rfv /var/www/html/resources/css \
    && rm -rfv /var/www/html/resources/js \
    && rm -rfv /var/www/html/resources/images \
    && rm -rfv /var/www/html/resources/fonts


### copy entrypoint and overwrite default one of base php image ###
COPY ./docker/app/docker-php-entrypoint-prod /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-php-entrypoint-prod \
    && chmod 770 /usr/local/bin/docker-php-entrypoint-prod


# be sure nginx is properly passing to php-fpm and fpm is responding
#HEALTHCHECK --interval=5s --timeout=3s CMD curl -f "localhost$FPM_PING_URI" || exit 1

# 80 - for nginx
EXPOSE 80


ENTRYPOINT ["docker-php-entrypoint-prod"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]


# TODO think of adding base auth for $FPM_PING_URI $FPM_STATUS_URI $NGINX_STATUS_URI pages
#RUN /bin/bash -c "htpasswd -bn default secret > /etc/nginx/conf.d/nginx.htpasswd"
#COPY ./docker/app/nginx.htpasswd /etc/nginx/conf.d/nginx.htpasswd
