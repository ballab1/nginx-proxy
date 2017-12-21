FROM alpine:3.6

ARG TZ=America/New_York
ARG nginx_user=nginx
ARG nginx_group=nginx
ARG nginx_uid=1001
ARG nginx_gid=1001

ENV NGINX_PKGS="bash nginx shadow openssl tzdata"

#
# PACKAGES
#
COPY build /tmp/ 

RUN set -o errexit \
    \
    && apk update \
    && apk add --no-cache $NGINX_PKGS \
    \
    && echo $TZ > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/*

#
# RUN NGINX
#
#USER nginx
EXPOSE 80
EXPOSE 443
VOLUME ["/var/www"]
WORKDIR /var/www/
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx"]
