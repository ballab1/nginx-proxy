#!/bin/sh

set -o errexit

export WWW="/var/www"

cd "${WWW}"
echo ">> DOCKER-ENTRYPOINT: EXECUTING CMD"
if [ "$1" = 'nginx' ]; then
    nginx -g "daemon off;"
else
    exec $@
fi