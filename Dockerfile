FROM alpine:3.6

ARG TZ=UTC

#
# PACKAGES
#
COPY etc_nginx.tar /tmp/etc_nginx.tar
COPY docker-entrypoint.sh /opt/docker-entrypoint.sh

RUN set -e \
    && apk update \
    && apk add tzdata \
    && echo $TZ > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && apk del tzdata \
    && apk add --no-cache \
            bash \
            nginx \
            shadow \
            openssl \
    && chmod u+rx,g+rx,o+rx,a-w /opt/docker-entrypoint.sh \
    && usermod -u 10777 nginx \
    && groupmod -g 10777 nginx \
    && mkdir -p /www \
    && mkdir -p /opt/ssl \
    && chown -R nginx:nginx /opt \
    && chown -R nginx:nginx /var/log/nginx \
    && mkdir -p /nginx/tmp \
    && chown -R nginx:nginx /nginx \
    && rm -rf /etc/nginx/* \
    && tar -xvf /tmp/etc_nginx.tar -C /etc/nginx \
    && cd /etc/nginx/ssl \
    && openssl genrsa -des3 -passout pass:x -out server.pass.key 2048 \
    && openssl rsa -passin pass:x -in server.pass.key -out server.key \
    && rm server.pass.key \
    && openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048 \
    && openssl req -new -key server.key -out server.csr -subj "/C=US/ST=Massachusetts/L=Mansfield/O=ballantyne.io/OU=docker.nginx.io/CN=ubuntu-s3" \
    && openssl x509 -req -sha256 -days 300065 -in server.csr -signkey server.key -out server.crt


RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

#
# RUN NGINX
#
#USER nginx
EXPOSE 80
EXPOSE 443
VOLUME ["/www"]
WORKDIR /www/
ENTRYPOINT ["/opt/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
