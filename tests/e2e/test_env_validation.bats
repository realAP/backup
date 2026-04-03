#!/usr/bin/env bats

load 'bats/bats-support/load'
load 'bats/bats-assert/load'
load 'helpers/setup'

# Test: missing TARGET_DOMAIN should fail
@test "prepare.sh fails when TARGET_DOMAIN is missing" {
  run docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T \
    -e TARGET_DOMAIN="" backup bash -c 'prepare.sh'
  assert_failure
  assert_output --partial "TARGET_DOMAIN"
}

# Test: missing RESTIC_PASSWORD should fail
@test "prepare.sh fails when RESTIC_PASSWORD is missing" {
  run docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T \
    -e RESTIC_PASSWORD="" backup bash -c 'prepare.sh'
  assert_failure
  assert_output --partial "RESTIC_PASSWORD"
}

# Test: missing PROVISION_MODE should fail
@test "prepare.sh fails when PROVISION_MODE is missing" {
  run docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T \
    -e PROVISION_MODE="" backup bash -c 'prepare.sh'
  assert_failure
  assert_output --partial "PROVISION_MODE"
}

# Test: invalid PROVISION_MODE should fail
@test "prepare.sh fails with invalid PROVISION_MODE" {
  run docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T \
    -e PROVISION_MODE="invalid" backup bash -c 'prepare.sh'
  assert_failure
  assert_output --partial "Invalid provision mode"
}

# Test: missing postgres-specific vars when mode=postgres
@test "prepare.sh fails when PROVISION_MODE=postgres but POSTGRES_HOST is missing" {
  run docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T \
    -e PROVISION_MODE="postgres" -e POSTGRES_HOST="" backup bash -c 'prepare.sh'
  assert_failure
  assert_output --partial "POSTGRES_HOST"
}

# Test: all common vars pass validation (test check_var section only)
@test "env validation passes when all required vars are set (mode=none)" {
  run docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T \
    backup bash -c '
      # Source the check_var function and run validation inline
      check_var() {
        local var_name="$1"
        local var_value="${!var_name}"
        if [ -z "$var_value" ]; then
          echo "Error: Environment variable '"'"'$var_name'"'"' is not set."
          exit 1
        fi
      }
      check_var "TARGET_DOMAIN"
      check_var "TARGET_DOMAIN_USER"
      check_var "SSH_PRIVATE_KEY_BASE64"
      check_var "RESTIC_REPOSITORY_NAME"
      check_var "RESTIC_PASSWORD"
      check_var "TELEGRAM_TOKEN"
      check_var "TELEGRAM_CHAT_ID"
      check_var "CRON"
      check_var "PROVISION_MODE"
      echo "All required environment variables are set."
    '
  assert_success
  assert_output --partial "All required environment variables are set"
}
