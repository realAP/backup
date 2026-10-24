#!/usr/bin/env bash
set -e

### check if all environment variables are set
# Function to check if a variable is set
check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    if [ -z "$var_value" ]; then
        echo "Error: Environment variable '$var_name' is not set."
        exit 1
    fi
}

# Common environment variables
check_var "TARGET_DOMAIN"
check_var "TARGET_DOMAIN_USER"
check_var "SSH_PRIVATE_KEY_BASE64"
check_var "RESTIC_REPOSITORY_NAME"
check_var "RESTIC_PASSWORD"
check_var "TELEGRAM_TOKEN"
check_var "TELEGRAM_CHAT_ID"
check_var "CRON"
check_var "PROVISION_MODE"

# Check environment variables based on provision mode
case "$PROVISION_MODE" in
    postgres)
        echo "Provision mode: postgres"
        check_var "POSTGRES_USER"
        check_var "POSTGRES_PASSWORD"
        check_var "POSTGRES_DATABASE"
        check_var "POSTGRES_HOST"
        ;;
    nextcloud)
        echo "Provision mode: nextcloud"
        check_var "NC_URL"
        check_var "NC_USER"
        check_var "NC_PASS"
        ;;
    none)
        echo "Provision mode: none"
        ;;
    *)
        echo "Error: Invalid provision mode '$PROVISION_MODE'. Expected 'postgres' or 'nextcloud' or 'none'."
        exit 1
        ;;
esac

# optional connection tuning, the defaults are applied in connection.sh
source /bin/connection.sh
if [[ ${starlink_enabled} -eq 1 ]]; then
    echo "Starlink mode: enabled"
    echo "  retries: ${BACKUP_RETRIES}, delay: ${BACKUP_RETRY_DELAY}s, connections: ${BACKUP_CONNECTIONS}, lock retry: ${BACKUP_LOCK_RETRY}"
    echo "  upload limit: ${BACKUP_UPLOAD_LIMIT:-unlimited}"
elif [ -n "$STARLINK_MODE" ]; then
    echo "Starlink mode: disabled (STARLINK_MODE='$STARLINK_MODE')"
fi

if ! [[ "$BACKUP_RETRIES" =~ ^[0-9]+$ ]] || [ "$BACKUP_RETRIES" -lt 1 ]; then
    echo "Error: 'BACKUP_RETRIES' has to be a number greater than 0, got '$BACKUP_RETRIES'."
    exit 1
fi
if ! [[ "$BACKUP_RETRY_DELAY" =~ ^[0-9]+$ ]]; then
    echo "Error: 'BACKUP_RETRY_DELAY' has to be a number of seconds, got '$BACKUP_RETRY_DELAY'."
    exit 1
fi

echo "All required environment variables are set."

### create folder which are over written when mounted
mkdir -p /source
mkdir -p /restore

## Backup specific parts not plugins
prepare_ssh.sh

## Feature specific parts
# currently nothing here
