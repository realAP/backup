#!/usr/bin/env bash


PGPASSWORD="${POSTGRES_PASSWORD}" pg_restore --clean -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} -v /source/backup.dump
