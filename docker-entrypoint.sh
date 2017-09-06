#!/bin/bash

set -e

#echo ">> DOCKER-ENTRYPOINT: GENERATING SSL CERT"
#cd /etc/nginx/ssl/
#openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
#openssl rsa -passin pass:x -in server.pass.key -out server.key
#rm server.pass.key
#openssl req -new -key server.key -out server.csr -subj "/C=US/ST=Massachusetts/L=Mansfield/O=ballantyne.io/OU=docker.nginx.io/CN=ubuntu-s3"
#openssl x509 -req -sha256 -days 300065 -in server.csr -signkey server.key -out server.crt
#echo ">> DOCKER-ENTRYPOINT: GENERATING SSL CERT ... DONE"

cd /www/

echo ">> DOCKER-ENTRYPOINT: EXECUTING CMD"
exec "$@"
