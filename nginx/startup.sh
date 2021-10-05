#!/bin/bash

if [ ! -f /etc/nginx/certs/default.crt ]; then
#    openssl req -x509 -out "/etc/nginx/certs/default.crt" -keyout "/etc/nginx/certs/default.key" \
#            -newkey rsa:2048 -nodes -sha256 \
#            -subj '/CN=localhost' -extensions EXT -config <( \
#            printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

    openssl genrsa -out "/etc/nginx/certs/default.key" 2048
    openssl req -new -key "/etc/nginx/certs/default.key" -out "/etc/nginx/certs/default.csr" -subj "/CN=default/O=default/C=UK"
    openssl x509 -req -days 365 -in "/etc/nginx/certs/default.csr" -signkey "/etc/nginx/certs/default.key" -out "/etc/nginx/certs/default.crt"
    chmod 644 /etc/nginx/certs/default.key
fi

# Start crond in background
crond -l 2 -b

# Start nginx in foreground
nginx
