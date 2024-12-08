#!/bin/env bash

### JUST FOR DEBUGGING
# Default values
RESTART_OPTION="--restart=always"
_DEBUG=0
# Check the first argument
if [[ "$#" -gt 0 ]]; then
  case $1 in
    DEBUG)
      RESTART_OPTION="-it --rm"
      _DEBUG=1
      shift
      ;;
    *)
      RESTART_OPTION="--rm"
      ;;
  esac
fi
###
source local.env
###

### create restore folder at the same level as the script
# Default paths based on the location of run_backup.sh
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Handle SCRIPT_RESTORE_DATA_TO
if [[ -z "$SCRIPT_RESTORE_DATA_TO" ]]; then
  SCRIPT_RESTORE_DATA_TO="$SCRIPT_DIR/restore"
  mkdir -p "$SCRIPT_RESTORE_DATA_TO"
  echo "Defaulting SCRIPT_RESTORE_DATA_TO to $SCRIPT_RESTORE_DATA_TO"
fi

# Handle SCRIPT_LOG_DIR
if [[ -n "$SCRIPT_LOG_DIR" ]]; then
  LOG_MOUNT="-v ${SCRIPT_LOG_DIR}:/var/log"
  echo "Mounting log directory: $SCRIPT_LOG_DIR"
else
  LOG_MOUNT=""
  echo "Skipping log directory mount"
fi

# Handle SCRIPT_DATA_TO_BACKUP
if [[ "$SCRIPT_DATA_TO_BACKUP" == "none" ]]; then
  SOURCE_MOUNT=""
  echo "Skipping bind a folder to container as source, SCRIPT_DATA_TO_BACKUP is set to 'none'"
elif [[ -z "$SCRIPT_DATA_TO_BACKUP" ]]; then
  SCRIPT_DATA_TO_BACKUP="$SCRIPT_DIR/source"
  mkdir -p "$SCRIPT_DATA_TO_BACKUP"
  SOURCE_MOUNT="-v ${SCRIPT_DATA_TO_BACKUP}:/source"
  echo "Defaulting SCRIPT_DATA_TO_BACKUP to $SCRIPT_DATA_TO_BACKUP"
else
  SOURCE_MOUNT="-v ${SCRIPT_DATA_TO_BACKUP}:/source"
  echo "Mounting data to backup directory: $SCRIPT_DATA_TO_BACKUP"
fi


docker run ${RESTART_OPTION} --network=backup_default --hostname backup \
  -v "${SCRIPT_RESTORE_DATA_TO}":/restore \
  $LOG_MOUNT \
  $SOURCE_MOUNT \
  -e "DEBUG"="${_DEBUG}" \
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
