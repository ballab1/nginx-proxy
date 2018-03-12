#!/bin/sh

cd "${WWW}"
echo ">> DOCKER-ENTRYPOINT: EXECUTING CMD"
nginx -g "daemon off;"
