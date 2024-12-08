#!/usr/bin/env bash
set -e

date
echo "+------------------------------------------------------+"
echo "|::::::::::::::::execute postgres_backup:::::::::::::::|"
echo "+------------------------------------------------------+"
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} -F c -f /source/backup.dump
echo "==========================DONE=========================="
