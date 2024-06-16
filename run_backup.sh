#!/bin/env bash
source .env
docker run --restart=always --rm -it --hostname restic \
  -v "${DATA_TO_BACKUP}":/source \
  -v "${ENV_NAME_OF_PRIVATE_KEY}":/private_key \
  -v ./restore:/restore \
  -v ./log/:/var/log \
  -v "${DATA_TO_BACKUP}":/source \
  -v "${ENV_PATH_OF_PRIVATE_KEY}":/private_key \
  -e "DEBUG"=0 \
  -e "TARGET_DOMAIN"="${ENV_TARGET_DOMAIN}" \
  -e "TARGET_DOMAIN_USER"="${ENV_TARGET_DOMAIN_USER}" \
  -e "PATH_OF_PRIVATE_KEY"="${ENV_PATH_OF_PRIVATE_KEY}" \
  -e "NC_URL"="${ENV_NC_URL}" \
  -e "NC_USER"="${ENV_NC_USER}" \
  -e "NC_PASS"="${ENV_NC_PASS}" \
  -e "RESTIC_REPOSITORY_NAME"="${ENV_RESTIC_REPOSITORY_NAME}" \
  -e "RESTIC_PASSWORD"="${ENV_RESTIC_PASSWORD}" \
  -e "TELEGRAM_TOKEN"="${ENV_TELEGRAM_TOKEN}" \
  -e "TELEGRAM_CHAT_ID"="${ENV_TELEGRAM_CHAT_ID}" \
  -e "CRON"='0 1 * * *' \
  restic $@