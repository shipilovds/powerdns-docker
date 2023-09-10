# PowerDNS & PowerDNS-Admin docker images

## Build and push docker

Manual usage: run `make REGISTRY_PASSWORD=yourpassword` 

You can try to rewrite other variables.

### Requirements

- make
- docker
- docker compose plugin

### Makefile Variables

```
REGISTRY_USER - docker registry user name
REGISTRY_PASSWORD - docker registry user password
REGISTRY_ADDR - docker registry server name (:server_port)
PDNS_VERSION - version of PowerDNS release to build
PDNS_ADMIN_VERSION - version of PowerDNS-Admin release to build
PDNS_IMAGE_NAME - PowerDNS docker image name
PDNS_ADMIN_IMAGE_NAME -  PowerDNS-Admin docker image name
```

## Test run

To run containers for test:

`make test-run.yml` - generates docker-compose conf

then `docker-compose -f test-run.yml up -d`

> NOTE: you can use `init.sql` as the example of postgres init script for your deployments
> `test-run.yml` might be used for the same purposes

## Configure services

### powernds

`pdns` image has mechanism that searches env variables and generates `pdns.conf` from them by template:

`PDNS_{anything}` - it takes `{anything}` and put it in `pdns.conf` (UPPERCASE->lowercase, "_" -> "-")

Image already has theese few variables:

```
PDNS_guardian=yes
PDNS_setuid=pdns
PDNS_setgid=pdns
PDNS_launch=gpgsql
```

#### Default variables

```
PDNS_MASTER=yes                     - Whis one is master (yes/no)
PDNS_API=yes                        - api enabled (yes/no)
PDNS_API_KEY=secret                 - api secret
PDNS_WEBSERVER=yes                  - WEB server enabled (yes/no)
PDNS_WEBSERVER_ALLOW_FROM=0.0.0.0/0 - web server white list
PDNS_WEBSERVER_ADDRESS=0.0.0.0      - pdns server bind address
PDNS_VERSION_STRING=anonymous       - version string. See vendor docs.
PDNS_DEFAULT_TTL=300                - Default records TTL (5m set)
PDNS_GPGSQL_HOST=postgres           - DB connection variables here and below
PDNS_GPGSQL_PORT=5432
PDNS_GPGSQL_DBNAME=powerdns
PDNS_GPGSQL_USER=pdns
PDNS_GPGSQL_PASSWORD=powerdns
```

### pdns-admin

`pdns` image has similar templating mechanism next to `pdns`

Look at default variables and you will understand

#### Default variables

```
PDNS_ADMIN_PDNS_STATS_URL=http://pdns:8081 - powerdns api url to check connection
PDNS_ADMIN_PDNS_API_KEY=secret             - pdns api secret
PDNS_ADMIN_PDNS_VERSION=0.4.1              - version. dunno y ¯\_(ツ)_/¯
PDNS_ADMIN_HSTS_ENABLED=False              - HTTP Strict Transport Security enabled (True/False)
PDNS_ADMIN_PORT=8000                       - unicorn port
PDNS_ADMIN_BIND_ADDRESS=0.0.0.0            - unicorn bind address
PDNS_ADMIN_LOGIN_TITLE=PDNS                - UI title text
PDNS_ADMIN_SAML_ENABLED=False              - SAML Authnetication
PDNS_ADMIN_CAPTCHA_ENABLE=False            - CAPTCHA enabled (True/False)
PDNS_ADMIN_SESSION_TYPE=sqlalchemy         - Prevent from failing (already forgotten wisdom)
PDNS_ADMIN_LOG_FILE=/dev/stdout            - Log to stdout
PDNS_ADMIN_LOG_LEVEL=WARN                  - Log warnings and errors only
PDNS_ADMIN_SQLA_DB_HOST=postgres           - DB connection variables here and below
PDNS_ADMIN_SQLA_DB_PORT=5432
PDNS_ADMIN_SQLA_DB_USER=pdns
PDNS_ADMIN_SQLA_DB_PASSWORD=powerdns
PDNS_ADMIN_SQLA_DB_NAME=powerdnsadmin
```
