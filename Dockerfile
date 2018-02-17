ARG FROM_BASE=base_container:20180217
FROM $FROM_BASE


# version of this docker image
ARG CONTAINER_VERSION=1.0.2
LABEL version=$CONTAINER_VERSION  

ENV NAGIOS_HOME=/usr/local/nagios

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/container/build.sh \
    && /tmp/container/build.sh 'NGINX'
RUN rm -rf /tmp/* 

# export ports for HTTP and HTTPS
EXPOSE 80
EXPOSE 443

VOLUME ["/var/www"]
WORKDIR /var/www/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx"]
