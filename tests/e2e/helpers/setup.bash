#!/usr/bin/env bash

# Common variables
export COMPOSE_FILE="${BATS_TEST_DIRNAME}/docker-compose.e2e.yaml"
export COMPOSE_PROJECT="e2e"

# Run a command inside the backup container
run_in_backup() {
  docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T backup bash -c "$*"
}

# Initialize restic environment inside the backup container
# Uses local repository instead of SFTP for E2E tests
init_backup_env() {
  run_in_backup '
    export RESTIC_REPOSITORY="/restic-repo"
    declare -p | grep -Ev "BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID" > /container.env
  '
}

# Run a command in the backup container with the full environment loaded
run_backup_cmd() {
  docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" exec -T backup bash -c '
    source /container.env 2>/dev/null
    export RESTIC_REPOSITORY="/restic-repo"
    '"$*"
}

# Wait for a service to be healthy
wait_for_healthy() {
  local service="$1"
  local max_wait="${2:-60}"
  local elapsed=0
  while [ $elapsed -lt $max_wait ]; do
    local health
    health=$(docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" ps --format json "$service" 2>/dev/null | grep -o '"Health":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ "$health" = "healthy" ]; then
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "Timed out waiting for $service to be healthy after ${max_wait}s" >&2
  return 1
}

# Clean up restic repository
clean_restic_repo() {
  run_in_backup 'rm -rf /restic-repo/*' 2>/dev/null || true
}

# Clean source and restore volumes
clean_volumes() {
  run_in_backup 'rm -rf /source/* /restore/*' 2>/dev/null || true
}

# Get telegram mock log content
get_telegram_logs() {
  run_in_backup 'cat /telegram-logs/messages.log 2>/dev/null' || true
}
