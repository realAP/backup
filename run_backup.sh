#!/bin/env bash

RESTART_OPTION="--restart=always"
SCRIPT_DEBUG=0
while [[ "$#" -gt 0 ]]; do
  case $1 in
    DEBUG) RESTART_OPTION="--rm -it"; SCRIPT_DEBUG=1; shift ;;
    *) break ;;
  esac
done

source local.env
docker run ${RESTART_OPTION} --network=backup_default --hostname backup \
  -v ./restore:/restore \
  -v ./log/:/var/log \
  -v "${DATA_TO_BACKUP}":/source \
  -e "DEBUG"="${SCRIPT_DEBUG}" \
  -e "TARGET_DOMAIN"="${ENV_TARGET_DOMAIN}" \
  -e "TARGET_DOMAIN_USER"="${ENV_TARGET_DOMAIN_USER}" \
  -e "SSH_PRIVATE_KEY"="${ENV_SSH_PRIVATE_KEY}" \
  -e "NC_URL"="${ENV_NC_URL}" \
  -e "NC_USER"="${ENV_NC_USER}" \
  -e "NC_PASS"="${ENV_NC_PASS}" \
  -e "RESTIC_REPOSITORY_NAME"="${ENV_RESTIC_REPOSITORY_NAME}" \
  -e "RESTIC_PASSWORD"="${ENV_RESTIC_PASSWORD}" \
  -e "TELEGRAM_TOKEN"="${ENV_TELEGRAM_TOKEN}" \
  -e "TELEGRAM_CHAT_ID"="${ENV_TELEGRAM_CHAT_ID}" \
  -e POSTGRES_USER="${ENV_POSTGRES_USER}" \
  -e POSTGRES_PASSWORD="${ENV_POSTGRES_PASSWORD}" \
  -e POSTGRES_DATABASE="${ENV_POSTGRES_DATABASE}" \
  -e POSTGRES_HOST="${ENV_POSTGRES_HOST}" \
  -e PROVISION_MODE="${ENV_PROVISION_MODE}" \
  -e "CRON"="${ENV_CRON}" \
  devp1337/backup:latest "${@}"
