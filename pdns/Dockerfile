FROM alpine:3.12
LABEL org.opencontainers.image.source=https://github.com/shipilovds/powerdns-docker

ARG VERSION

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

ENV PDNS_guardian=yes \
    PDNS_setuid=pdns \
    PDNS_setgid=pdns \
    PDNS_launch=gpgsql

COPY pdns.conf.tpl /
COPY entrypoint.sh /docker-entrypoint.sh

EXPOSE 53 53/udp

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "/usr/sbin/pdns_server", "--write-pid=no", "--disable-syslog=yes" ]
