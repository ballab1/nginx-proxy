FROM alpine:3.6

ARG TZ=UTC
ARG user=nginx
ARG group=nginx
ARG uid=10777
ARG gid=10777

#
# PACKAGES
#
COPY etc_nginx.tgz /tmp/etc_nginx.tgz
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN set -e \
    && apk update \
    && apk add tzdata \
    && echo $TZ > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && apk add --no-cache \
            bash \
            nginx \
            shadow \
            openssl \
    && chmod u+rx,g+rx,o+rx,a-w /docker-entrypoint.sh \
    && usermod -u ${uid} ${user} \
    && groupmod -g ${gid} ${group} \
    && mkdir -p /www \
    && mkdir -p /opt/ssl \
    && chown -R nginx:nginx /opt \
    && chown -R nginx:nginx /var/log/nginx \
    && mkdir -p /nginx/tmp \
    && chown -R nginx:nginx /nginx \
    && rm -rf /etc/nginx/* \
    && tar -xvzf /tmp/etc_nginx.tgz -C /etc/nginx \
    && mkdir -p /etc/nginx/ssl \
    && cd /etc/nginx/ssl \
    && openssl genrsa -des3 -passout pass:x -out server.pass.key 2048 \
    && openssl rsa -passin pass:x -in server.pass.key -out server.key \
    && rm server.pass.key \
    && openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048 \
    && openssl req -new -key server.key -out server.csr -subj "/C=US/ST=Massachusetts/L=Mansfield/O=ballantyne.io/OU=docker.nginx.io/CN=ubuntu-s3" \
    && openssl x509 -req -sha256 -days 300065 -in server.csr -signkey server.key -out server.crt


#RUN ln -sf /dev/stdout /var/log/nginx/access.log \
#    && ln -sf /dev/stderr /var/log/nginx/error.log

#
# RUN NGINX
#
#USER nginx
EXPOSE 80
EXPOSE 443
VOLUME ["/www"]
WORKDIR /www/
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
