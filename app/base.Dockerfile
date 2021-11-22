# vasymus/base-php-nginx-node:php-8.0.12-nginx-1.20.1-node-14.18.1
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
    zip \
    unzip \
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
        #&& apt-get remove --purge --auto-remove -y \
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
    # exclude packages from autoremove that are used @see https://askubuntu.com/a/943292
    && apt-mark manual curl dos2unix supervisor wget openssh-client ca-certificates nginx gettext-base \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version

# install composer from official image @see https://hub.docker.com/_/composer
COPY --from=composer:2.1.9 /usr/bin/composer /usr/bin/composer

### / PREPARATION PART of image ###
