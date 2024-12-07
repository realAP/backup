#!/usr/bin/env bash

PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} -F c -f /source/backup.dump
