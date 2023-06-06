FROM alpine:3.18

# install packages
RUN apk upgrade --no-cache \
        && apk add --no-cache \
        postsrsd \
        s6 setpriv

# add the custom configurations
COPY rootfs/ /

# default postsrsd ports
EXPOSE 10001/tcp 10002/tcp

CMD [ "/entrypoint.sh" ]

