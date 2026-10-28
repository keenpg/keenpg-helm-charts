#!/bin/sh
# Starts the console's PostgreSQL. Works with KeenPG/upstream "crunchy-postgres" style images
# (binaries in /usr/pgsql-NN/bin) and with the official postgres images.
# Everything comes from the environment (see statefulset.yaml):
#   PGDATA, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, PGPORT, PG_SOCKET_DIR, PG_MAX_CONNECTIONS
set -eu

PGDATA="${PGDATA:?PGDATA is not set}"
PGPORT="${PGPORT:-5432}"
PG_SOCKET_DIR="${PG_SOCKET_DIR:-/tmp}"
PG_MAX_CONNECTIONS="${PG_MAX_CONNECTIONS:-50}"

if command -v initdb >/dev/null 2>&1; then
  BIN="$(dirname "$(command -v initdb)")"
else
  BIN="$(ls -d /usr/pgsql-*/bin /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -n 1)"
fi
if [ -z "${BIN}" ] || [ ! -x "${BIN}/initdb" ]; then
  echo "keenpgo-console-db: initdb was not found in this image" >&2
  exit 1
fi

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  echo "keenpgo-console-db: creating a new database cluster in ${PGDATA}"
  mkdir -p "${PGDATA}"
  chmod 700 "${PGDATA}"
  pwfile="$(mktemp)"
  printf '%s' "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is not set}" > "${pwfile}"
  "${BIN}/initdb" -D "${PGDATA}" -U "${POSTGRES_USER:?POSTGRES_USER is not set}" --pwfile="${pwfile}" \
    -E UTF8 --locale=C --auth-local=scram-sha-256 --auth-host=scram-sha-256
  rm -f "${pwfile}"
  echo "host all all all scram-sha-256" >> "${PGDATA}/pg_hba.conf"
  if [ "${POSTGRES_DB:-postgres}" != "postgres" ]; then
    echo "CREATE DATABASE \"${POSTGRES_DB}\" OWNER \"${POSTGRES_USER}\";" | \
      "${BIN}/postgres" --single -D "${PGDATA}" -c unix_socket_directories="${PG_SOCKET_DIR}" postgres >/dev/null
  fi
fi

exec "${BIN}/postgres" -D "${PGDATA}" \
  -c listen_addresses='*' \
  -c port="${PGPORT}" \
  -c unix_socket_directories="${PG_SOCKET_DIR}" \
  -c max_connections="${PG_MAX_CONNECTIONS}" \
  -c password_encryption=scram-sha-256
