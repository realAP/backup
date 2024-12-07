#!/bin/env bash

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --always) RESTART_OPTION="--restart=always"; shift ;;
    *) break ;;
  esac
done

source local.env
docker run ${RESTART_OPTION} -it --network=backup_default --hostname backup \
  -v ./restore:/restore \
  -v ./log/:/var/log \
  -v "${DATA_TO_BACKUP}":/source \
  -e "DEBUG"=1 \
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
  -e "CRON"="${ENV_CRON_SCHEDULE}" \
  devp1337/backup:latest $@
