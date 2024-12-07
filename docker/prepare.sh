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
check_var "SSH_PRIVATE_KEY"
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
    *)
        echo "Error: Invalid provision mode '$PROVISION_MODE'. Expected 'postgres' or 'nextcloud'."
        exit 1
        ;;
esac

echo "All required environment variables are set."

### create folder which are over written when mounted
mkdir -p /source
mkdir -p /restore

## Backup specific parts not plugins
prepare_ssh.sh

## Feature specific parts
# currently nothing here
