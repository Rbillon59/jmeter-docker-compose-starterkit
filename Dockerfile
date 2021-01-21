# Lightweight distro
FROM alpine:3

## Installing java and dependencies
RUN    apk update \
    && apk upgrade \
    && apk add ca-certificates \
    && update-ca-certificates \
    && apk add --update openjdk8-jre tzdata curl unzip bash coreutils \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /opt/jmeter/results \
    && mkdir /opt/jmeter/logs/ \
    && mkdir /temp

ENTRYPOINT ["/opt/entrypoint.sh"]

COPY ./entrypoint.sh /opt/entrypoint.sh
COPY ./apache-jmeter-5.2.1 /opt/jmeter
ENV HOME /opt/jmeter/
