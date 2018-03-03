ARG FROM_BASE=base_container:20180217
FROM $FROM_BASE

# name and version of this docker image
ARG CONTAINER_NAME=nginx
ARG CONTAINER_VERSION=1.0.0

LABEL org_name=$CONTAINER_NAME \
      version=$CONTAINER_VERSION 

# set to non zero for the framework to show verbose action scripts
ARG DEBUG_TRACE=0


# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME"
RUN [[ $DEBUG_TRACE != 0 ]] || rm -rf /tmp/* 


# export ports for HTTP and HTTPS
EXPOSE 80
EXPOSE 443

VOLUME ["/var/www"]
WORKDIR /var/www/


ENTRYPOINT ["docker-entrypoint.sh"]
#CMD ["$CONTAINER_NAME"]
CMD ["nginx"]
