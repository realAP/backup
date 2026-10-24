#!/usr/bin/env bash
set -e

source /bin/connection.sh

restic_opts=()
if [[ -n "${BACKUP_CONNECTIONS}" ]]; then
  restic_opts+=(-o "sftp.connections=${BACKUP_CONNECTIONS}")
fi
if [[ -n "${BACKUP_UPLOAD_LIMIT}" ]]; then
  restic_opts+=(--limit-upload "${BACKUP_UPLOAD_LIMIT}")
fi

# a backup which died mid transfer leaves a lock behind, the next run should
# wait for it instead of failing right away
lock_opts=()
if [[ -n "${BACKUP_LOCK_RETRY}" ]]; then
  lock_opts+=(--retry-lock "${BACKUP_LOCK_RETRY}")
fi

# retries the given command with a growing delay, BACKUP_RETRIES=1 means the
# command is executed exactly once like it was before
retry() {
  local label="$1"
  shift
  local attempt=1
  local delay="${BACKUP_RETRY_DELAY}"

  while true; do
    if "$@"; then
      return 0
    fi
    if [[ ${attempt} -ge ${BACKUP_RETRIES} ]]; then
      echo "!!! ${label} failed after ${attempt} attempt(s)"
      return 1
    fi
    echo "!!! ${label} failed (attempt ${attempt}/${BACKUP_RETRIES}), next try in ${delay}s"
    sleep "${delay}"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
  done
}

ensure_repository() {
  if restic "${restic_opts[@]}" cat config > /dev/null 2>&1; then
    return 0
  fi
  echo "repository is not readable, trying to initialize it"
  if restic "${restic_opts[@]}" init; then
    return 0
  fi
  # init refuses to touch an existing repository, so the read above may have
  # failed because the link was down - retry reading before giving up
  retry "repository read" restic "${restic_opts[@]}" cat config > /dev/null
}

echo "=========LET'S DO THIS, BACKUP THE SHIT!!!========="
date
if [[ ${starlink_enabled} -eq 1 ]]; then
  echo "starlink mode enabled: retries=${BACKUP_RETRIES} delay=${BACKUP_RETRY_DELAY}s connections=${BACKUP_CONNECTIONS} lock-retry=${BACKUP_LOCK_RETRY}"
fi

ensure_repository

echo "+------------------------------------------+"
echo "|::::::::::::::::call backup:::::::::::::::|"
echo "+------------------------------------------+"
retry "backup" restic "${restic_opts[@]}" "${lock_opts[@]}" backup /source

echo "+------------------------------------------+"
echo "|::::::::::::::::call check::::::::::::::::|"
echo "+------------------------------------------+"
retry "check" restic "${restic_opts[@]}" "${lock_opts[@]}" check

echo "+------------------------------------------+"
echo "|::::::::::::::::call forget:::::::::::::::|"
echo "+------------------------------------------+"
retry "forget" restic "${restic_opts[@]}" "${lock_opts[@]}" forget --keep-weekly 52 --keep-monthly 12 --keep-yearly 100

echo "+------------------------------------------+"
echo "|::::::::::::::::call check::::::::::::::::|"
echo "+------------------------------------------+"
retry "check" restic "${restic_opts[@]}" "${lock_opts[@]}" check

echo "==================DONE====================="
