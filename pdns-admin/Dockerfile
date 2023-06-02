FROM alpine:3.17 AS builder

ARG VERSION

RUN apk add --no-cache \
    cargo \
    curl \
    gcc \
    libffi-dev \
    libldap \
    libxml2-dev \
    libxslt-dev \
    musl-dev \
    npm \
    openldap-dev \
    openssl \
    openssl-dev \
    postgresql-dev \
    postgresql-libs \
    python3 \
    python3-dev \
    py3-lxml \
    py3-pip \
    py3-wheel \
    py3-certifi \
    py3-chardet \
    py3-idna \
    py3-urllib3 \
    rust \
    tzdata \
    xmlsec \
    xmlsec-dev \
    yarn

RUN addgroup -S -g 2000 pda \
 && adduser -S -u 2000 -D -G pda pda \
 && chown -R pda:pda /opt

USER pda

RUN mkdir -p /opt/powerdns-admin \
 && curl -sSL https://github.com/ngoduykhanh/PowerDNS-Admin/archive/v$VERSION.tar.gz | tar -xzC /opt/powerdns-admin --strip 1

RUN sed -i '/mysqlclient.*/d' /opt/powerdns-admin/requirements.txt \
 && PATH=$PATH:~/.local/bin pip3 install --upgrade pip \
 && PATH=$PATH:~/.local/bin pip3 install --no-cache-dir --user -r /opt/powerdns-admin/requirements.txt \
 && PATH=$PATH:~/.local/bin pip3 install --no-cache-dir --user \
    envtpl \
    python-dotenv \
    psycopg2-binary 

WORKDIR /opt/powerdns-admin

RUN yarn install --pure-lockfile \
&& yarn cache clean \
 && sed -i -r -e "s|'cssmin',\s?'cssrewrite'|'cssmin'|g" powerdnsadmin/assets.py \
 && PATH=$PATH:~/.local/bin FLASK_APP=/opt/powerdns-admin/powerdnsadmin/__init__.py flask assets build \
 && find powerdnsadmin/static/node_modules -name 'fonts' -exec cp -r {} powerdnsadmin/static ";" \
 && find powerdnsadmin/static/node_modules/icheck/skins/square -name '*.png' -exec cp {} powerdnsadmin/static/generated ";" \
 && rm -rf powerdnsadmin/custom \
 && rm -rf powerdnsadmin/node_modules \
 && rm -rf powerdnsadmin/static/node_modules

COPY assets.py powerdnsadmin/

RUN pip uninstall cssmin jsmin pytest -y


FROM alpine:3.17
LABEL org.opencontainers.image.source=https://github.com/shipilovds/powerdns-docker

ENV FLASK_APP=/opt/powerdns-admin/powerdnsadmin/__init__.py \
    PATH=$PATH:/opt/.local/bin \
    PYTHONPATH=/opt/.local/lib/python3.8/site-packages:/usr/lib/python3.8/site-packages

COPY --from=builder /opt/powerdns-admin /opt/powerdns-admin
COPY --from=builder /home/pda/.local /opt/.local

RUN apk add --no-cache \
    curl \
    libldap \
    libressl \
    postgresql-client \
    postgresql-libs \
    python3 \
    py3-certifi \
    py3-chardet \
    py3-idna \
    py3-lxml \
    py3-urllib3 \
    tzdata \
    xmlsec

RUN addgroup -S -g 2000 pda \
 && adduser -S -u 2000 -D -G pda pda \
 && chown -R pda:pda /opt

USER pda

WORKDIR /opt/powerdns-admin

COPY config.py.tpl .

COPY entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
