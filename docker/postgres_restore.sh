#!/usr/bin/env bash
set -e

date
echo "+------------------------------------------------------+"
echo "|::::::::::::::::execute postgres_restore:::::::::::::::|"
echo "+------------------------------------------------------+"
PGPASSWORD="${POSTGRES_PASSWORD}" pg_restore --clean -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} -v /restore/source/backup.dump
echo "==========================DONE=========================="
