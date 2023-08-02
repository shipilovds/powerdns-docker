FROM alpine:3.17 AS builder

ARG VERSION

ARG BUILD_DEPENDENCIES="build-base \
    libffi-dev \
    libpq-dev \
    libxml2-dev \
    mariadb-connector-c-dev \
    openldap-dev \
    python3-dev \
    xmlsec-dev \
    npm \
    yarn \
    cargo"

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    FLASK_APP=/build/powerdnsadmin/__init__.py

# Get dependencies
# py3-pip should not belong to BUILD_DEPENDENCIES. Otherwise, when we remove
# them with "apk del" at the end of build stage, the python requests module
# will be removed as well - (Tested with alpine:3.12 and python 3.8.5).
RUN apk add --no-cache ${BUILD_DEPENDENCIES} && \
    apk add --no-cache py3-pip curl py3-yaml

WORKDIR /build

# Add sources
RUN curl -sSL https://github.com/PowerDNS-Admin/PowerDNS-Admin/archive/refs/tags/v$VERSION.tar.gz | tar -xzC /build --strip 1

# Get application dependencies
RUN pip install --upgrade pip && \
    sed -i "s|PyYAML==5.4|PyYAML==6.0.0|g" /build/requirements.txt && \
    pip install --use-pep517 -r requirements.txt
RUN pip install \
    envtpl \
    python-dotenv \
    psycopg2-binary 

# Prepare assets
RUN yarn install --pure-lockfile --production && \
    yarn cache clean && \
    sed -i -r -e "s|'rcssmin',\s?'cssrewrite'|'rcssmin'|g" /build/powerdnsadmin/assets.py && \
    flask assets build

RUN mv /build/powerdnsadmin/static /tmp/static && \
    mkdir /build/powerdnsadmin/static && \
    cp -r /tmp/static/generated /build/powerdnsadmin/static && \
    cp -r /tmp/static/assets /build/powerdnsadmin/static && \
    cp -r /tmp/static/img /build/powerdnsadmin/static && \
    find /tmp/static/node_modules -name 'webfonts' -exec cp -r {} /build/powerdnsadmin/static \; && \
    find /tmp/static/node_modules -name 'fonts' -exec cp -r {} /build/powerdnsadmin/static \; && \
    find /tmp/static/node_modules/icheck/skins/square -name '*.png' -exec cp {} /build/powerdnsadmin/static/generated \;

RUN { \
      echo "from flask_assets import Environment"; \
      echo "assets = Environment()"; \
      echo "assets.register('js_login', 'generated/login.js')"; \
      echo "assets.register('js_validation', 'generated/validation.js')"; \
      echo "assets.register('css_login', 'generated/login.css')"; \
      echo "assets.register('js_main', 'generated/main.js')"; \
      echo "assets.register('css_main', 'generated/main.css')"; \
    } > /build/powerdnsadmin/assets.py

# Move application
RUN mkdir -p /app && \
    cp -r /build/migrations/ /build/powerdnsadmin/ /build/run.py /app 
    #&& \
    #mkdir -p /app/configs 
    #&& \
    #cp -r /build/configs/docker_config.py /app/configs

# Build image
FROM alpine:3.17

ENV FLASK_APP=/app/powerdnsadmin/__init__.py \
    USER=pda

RUN apk add --no-cache mariadb-connector-c postgresql-client py3-gunicorn py3-pyldap py3-flask py3-psycopg2 xmlsec tzdata libcap && \
    addgroup -S ${USER} && \
    adduser -S -D -G ${USER} ${USER} && \
    mkdir /data && \
    chown ${USER}:${USER} /data && \
    setcap cap_net_bind_service=+ep $(readlink -f /usr/bin/python3) && \
    apk del libcap

COPY --from=builder /usr/bin/flask /usr/bin/
COPY --from=builder /usr/bin/envtpl /usr/bin/
COPY --from=builder /usr/lib/python3.10/site-packages /usr/lib/python3.10/site-packages/
COPY --from=builder --chown=root:${USER} /app /app/
COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY config.py.tpl /app/
COPY Dockerfile /

WORKDIR /app
RUN chown -R ${USER}:${USER} /app 

EXPOSE 9393/tcp
USER ${USER}
HEALTHCHECK CMD ["wget","--output-document=-","--quiet","--tries=1","http://127.0.0.1:9393/"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["gunicorn","powerdnsadmin:create_app()"]
