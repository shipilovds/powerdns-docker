FROM alpine:3.18

ARG VERSION
LABEL org.opencontainers.image.source=https://github.com/shipilovds/powerdns-docker
LABEL org.opencontainers.image.description='Powerfull and dynamic image for PowerDNS Authoritative Server'
LABEL org.opencontainers.image.authors='@shipilovds (shipilovds@gmail.com)'
LABEL org.opencontainers.image.url=https://github.com/shipilovds/powerdns-docker
LABEL org.opencontainers.image.documentation=https://github.com/shipilovds/powerdns-docker/blob/main/README.md


RUN set -ex \
    && apk --no-cache add \
      boost-program_options \
      lua5.3-libs \
      libcurl \
      libgcc \
      libstdc++ \
      postgresql-client \
      py3-pip \
    \
    && apk --no-cache add --virtual build-deps \
      boost-dev \
      curl-dev \
      g++ \
      lua5.3-dev \
      make \
      postgresql-dev \
      wget \
    \
    && wget -qO - https://downloads.powerdns.com/releases/pdns-$VERSION.tar.bz2 | tar xjf - -C /tmp \
    && cd /tmp/pdns-$VERSION \
    && ./configure --sysconfdir=/etc --prefix=/usr --with-modules="gpgsql" --with-dynmodules="" \
    && make install \
    \
    && apk del build-deps \
    && cd / && rm -rf /tmp/*

RUN pip3 install --no-cache-dir envtpl

RUN addgroup -S -g 2000 pdns && adduser -S -u 2000 -D -G pdns pdns

RUN touch /etc/pdns.conf && chown pdns /etc/pdns.conf && chmod 700 /etc/pdns.conf
RUN mkdir /var/run/pdns/ && chown pdns /var/run/pdns && chmod 700 /var/run/pdns

ENV PDNS_guardian=yes \
    PDNS_setuid=pdns \
    PDNS_setgid=pdns \
    PDNS_launch=gpgsql

COPY pdns.conf.tpl /
COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY Dockerfile /

USER pdns
EXPOSE 5053 5053/udp
ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "/usr/sbin/pdns_server", "--write-pid=no", "--disable-syslog=yes", "--local-port=5053" ]
HEALTHCHECK CMD ["pdns_control", "rping"]
LABEL org.opencontainers.image.version=$VERSION
ARG REVISION
LABEL org.opencontainers.image.revision=$REVISION
