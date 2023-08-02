#!/bin/bash

set -euo pipefail

## DATABASE CONFIG
: "${PDNS_ADMIN_SQLA_DB_HOST:=postgres}"
: "${PDNS_ADMIN_SQLA_DB_PORT:=5432}"
: "${PDNS_ADMIN_SQLA_DB_USER:=pdns}"
: "${PDNS_ADMIN_SQLA_DB_PASSWORD:=powerdns}"
: "${PDNS_ADMIN_SQLA_DB_NAME:=powerdnsadmin}"

export PDNS_ADMIN_SQLA_DB_HOST PDNS_ADMIN_SQLA_DB_PORT PDNS_ADMIN_SQLA_DB_USER PDNS_ADMIN_SQLA_DB_PASSWORD PDNS_ADMIN_SQLA_DB_NAME
export PGPASSWORD=${PDNS_ADMIN_SQLA_DB_PASSWORD}

# POWERDNS CONFIG
: "${PDNS_ADMIN_PDNS_STATS_URL:=http://pdns:8081}"
: "${PDNS_ADMIN_PDNS_API_KEY:=secret}"
: "${PDNS_ADMIN_PDNS_VERSION:=4.4.1}"

export PDNS_ADMIN_PDNS_STATS_URL PDNS_ADMIN_PDNS_API_KEY PDNS_ADMIN_PDNS_VERSION

## BASIC APP CONFIG
: "${PDNS_ADMIN_HSTS_ENABLED:=False}"
: "${PDNS_ADMIN_PORT:=9393}"
: "${PDNS_ADMIN_BIND_ADDRESS:=0.0.0.0}"
: "${PDNS_ADMIN_LOGIN_TITLE:=PDNS}"
: "${PDNS_ADMIN_SAML_ENABLED:=False}"
# Generate secret key
[ -f .secret-key ] || tr -dc _A-Z-a-z-0-9 < /dev/urandom | head -c 32 > .secret-key || true
PDNS_ADMIN_SECRET_KEY="$(cat .secret-key)"

export PDNS_ADMIN_HSTS_ENABLED PDNS_ADMIN_PORT PDNS_ADMIN_BIND_ADDRESS PDNS_ADMIN_LOGIN_TITLE PDNS_ADMIN_SAML_ENABLED PDNS_ADMIN_SECRET_KEY

## CAPTCHA CONFIG
: "${PDNS_ADMIN_CAPTCHA_ENABLE:=False}"

export PDNS_ADMIN_CAPTCHA_ENABLE

# Prevent from failing
: "${PDNS_ADMIN_SESSION_TYPE:=sqlalchemy}"

export PDNS_ADMIN_SESSION_TYPE

## LOG CONFIG
: "${PDNS_ADMIN_LOG_FILE:=/dev/stdout}"
: "${PDNS_ADMIN_LOG_LEVEL:=WARN}"

export PDNS_ADMIN_LOG_FILE PDNS_ADMIN_LOG_LEVEL

envtpl < config.py.tpl > /app/powerdnsadmin/default_config.py

PSQL_COMMAND="psql -h ${PDNS_ADMIN_SQLA_DB_HOST} -p ${PDNS_ADMIN_SQLA_DB_PORT} -d ${PDNS_ADMIN_SQLA_DB_NAME} -U ${PDNS_ADMIN_SQLA_DB_USER}"

# Wait for us to be able to connect to PostgreSQL before proceeding
echo "===> Waiting for '$PDNS_ADMIN_SQLA_DB_HOST' PostgreSQL service..."
until pg_isready -h ${PDNS_ADMIN_SQLA_DB_HOST} -U ${PDNS_ADMIN_SQLA_DB_USER}; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 5
done

# Initialize DB if needed

# create the database schema
flask db upgrade

# initial settings if not available in the DB
$PSQL_COMMAND -c "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_url', '${PDNS_ADMIN_PDNS_STATS_URL}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_url') LIMIT 1;"
$PSQL_COMMAND -c "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_key', '${PDNS_ADMIN_PDNS_API_KEY}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_key') LIMIT 1;"
$PSQL_COMMAND -c "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_version', '${PDNS_ADMIN_PDNS_VERSION}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_version') LIMIT 1;"

# update pdns api settings if env changed
$PSQL_COMMAND -c "UPDATE setting SET value='${PDNS_ADMIN_PDNS_STATS_URL}' WHERE name='pdns_api_url';"
$PSQL_COMMAND -c "UPDATE setting SET value='${PDNS_ADMIN_PDNS_API_KEY}' WHERE name='pdns_api_key';"
$PSQL_COMMAND -c "UPDATE setting SET value='${PDNS_ADMIN_PDNS_VERSION}' WHERE name='pdns_version';"


echo "===> Waiting while PowerDNS API become available..."
count=1
until wget -q ${PDNS_ADMIN_PDNS_STATS_URL}
do
  ((count++))
  if [ $count -eq 6 ]; then
    echo "Stop trying to reach PowerDNS API. Exiting."
    exit 1
  fi
  echo "PowerDNS API is unavailable - sleeping"
  sleep 5
done

# start web server with powerdns-admin app
gunicorn -t 120 --workers 4 --bind "0.0.0.0:${PDNS_ADMIN_PORT}" --log-level info 'powerdnsadmin:create_app()'
