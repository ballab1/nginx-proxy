FROM alpine:3.6

ENV VERSION=1.0.0 \
    TZ="America/New_York"
    
LABEL version=$VERSION

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && apk update \
    && apk add --no-cache bash \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/*

# export ports for HTTP and HTTPS
EXPOSE 80
EXPOSE 443

VOLUME ["/var/www"]
WORKDIR /var/www/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx"]
