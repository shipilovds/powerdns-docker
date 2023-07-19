#!/bin/sh

set -euo pipefail

# Configure postgres env vars
: "${PDNS_GPGSQL_HOST:=postgres}"
: "${PDNS_GPGSQL_PORT:=5432}"
: "${PDNS_GPGSQL_DBNAME:=powerdns}"
: "${PDNS_GPGSQL_USER:=pdns}"
: "${PDNS_GPGSQL_PASSWORD:=powerdns}"

export PDNS_GPGSQL_HOST PDNS_GPGSQL_PORT PDNS_GPGSQL_DBNAME PDNS_GPGSQL_USER PDNS_GPGSQL_PASSWORD
export PGPASSWORD=${PDNS_GPGSQL_PASSWORD}

# Configure server base settings
: "${PDNS_MASTER:=yes}"
: "${PDNS_API:=yes}"
: "${PDNS_API_KEY:=secret}"
: "${PDNS_WEBSERVER:=yes}"
: "${PDNS_WEBSERVER_ALLOW_FROM:=0.0.0.0/0}"
: "${PDNS_WEBSERVER_ADDRESS:=0.0.0.0}"
: "${PDNS_VERSION_STRING:=anonymous}"
: "${PDNS_DEFAULT_TTL:=1500}"

export PDNS_MASTER PDNS_API PDNS_API_KEY PDNS_WEBSERVER PDNS_WEBSERVER_ALLOW_FROM PDNS_WEBSERVER_ADDRESS PDNS_VERSION_STRING PDNS_DEFAULT_TTL PDNS_SOA_MINIMUM_TTL

PSQL_COMMAND="psql -h ${PDNS_GPGSQL_HOST} -p ${PDNS_GPGSQL_PORT} -d ${PDNS_GPGSQL_DBNAME} -U ${PDNS_GPGSQL_USER}"

# Wait for us to be able to connect to PostgreSQL before proceeding
echo "===> Waiting for $PDNS_GPGSQL_HOST PostgreSQL service"
until pg_isready -h ${PDNS_GPGSQL_HOST} -U ${PDNS_GPGSQL_USER}; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 5
done

PSQL_CHECK_SCHEMA_STRING="${PSQL_COMMAND} -t -c \"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='domains');\" | sed '1q;d'"
PSQL_NUM_TABLE=$(eval $PSQL_CHECK_SCHEMA_STRING)
if [ "$PSQL_NUM_TABLE" != " t" ]; then
  echo "WARNING: PostgreSQL DB schema is absent!"
  $PSQL_COMMAND -a -f /usr/share/doc/pdns/schema.pgsql.sql
  echo "NOTE: PostgreSQL DB schema was initiated for the first time"
fi

# Create config file from template
envtpl < /pdns.conf.tpl > /etc/pdns.conf

exec "$@"
