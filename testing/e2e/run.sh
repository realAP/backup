#!/usr/bin/env bash
# E2E: postgres -> backup image -> sftp, restore and compare. Same call locally and in the pipeline.
#   ./testing/e2e/run.sh          run everything, clean up afterwards
#   KEEP=1 ./testing/e2e/run.sh   leave the stack running for debugging
#   SKIP_BUILD=1 ...              use the already built image backup-e2e:test
set -euo pipefail
cd "$(dirname "$0")"

W=.work
dc() { docker compose -p backup-e2e -f compose.yaml "$@"; }
# same, but the (very chatty) output is collapsed in the GitHub Actions log, not hidden
dcg() {
  local rc=0
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then echo "::group::docker compose $*"; fi
  dc "$@" || rc=$?
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then echo "::endgroup::"; fi
  return $rc
}
msgs() { cat "$W/telegram/messages.log" 2>/dev/null || true; }
has() { local m; m=$(msgs); grep -q "$1" <<< "$m"; }

# --- reporting: the test story stands out, docker output stays untouched in between ---
if [[ -z "${NO_COLOR:-}" ]]; then B=$'\e[1;36m' G=$'\e[1;32m' R=$'\e[1;31m' N=$'\e[0m'; else B="" G="" R="" N=""; fi
PASSED=()
LINE=$(printf '=%.0s' {1..78})
scenario() { printf '\n%s%s\n SCENARIO: %s\n%s%s\n' "$B" "$LINE" "$1" "$LINE" "$N"; }
step() { printf '\n%s>> %s%s\n' "$B" "$1" "$N"; }
pass() { PASSED+=("$1"); printf '%s   [OK] %s%s\n' "$G" "$1" "$N"; }
fail() {
  printf '\n%s   [FAILED] %s%s\n' "$R" "$1" "$N"
  echo "--- last lines of the backup container ---"; dc logs --no-color backup | tail -60
  echo "--- telegram messages received ---"; msgs
  exit 1
}
# check "what must be true" <command...>
check() { local what="$1"; shift; "$@" || fail "$what"; pass "$what"; }

cleanup() {
  [[ "${KEEP:-0}" == "1" ]] || dc down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for_message() {
  local pattern="$1" timeout="$2"
  for ((i = 0; i < timeout; i++)); do
    has "$pattern" && return 0
    sleep 1
  done
  return 1
}
no_failure_reported() { ! has "Failure"; }
psql() { dc exec -T db psql -U user -d database -tA -c "$1"; }
table_is_empty() { [[ "$(psql "SELECT count(*) FROM example_table")" == "0" ]]; }
original_row_is_back() { [[ "$(psql "SELECT name FROM example_table")" == "Sample Data" ]]; }
restored_dump_has_original_data() {
  dc run --rm -T --entrypoint bash backup -c 'pg_restore -f - /restore/source/backup.dump | grep -q "Sample Data"'
}

step "Preparing: ssh key pair for the backup target, pulling test images, building the backup image"
rm -rf "$W" && mkdir -p "$W/telegram"
ssh-keygen -q -t ed25519 -N '' -f "$W/id"
chmod 644 "$W/id.pub"
SSH_PRIVATE_KEY_BASE64=$(base64 -w0 < "$W/id")
export SSH_PRIVATE_KEY_BASE64
dc down -v --remove-orphans >/dev/null 2>&1 || true
dcg pull --quiet sftp db telegram
[[ -n "${SKIP_BUILD:-}" ]] || dcg build backup

# ---------------------------------------------------------------------------
scenario "1 - Daily backup: database is backed up to the SFTP server and can be restored"

step "A database with one known row and an empty SFTP server are started, then the backup container runs its first backup"
export STARLINK_MODE=false
dcg up -d sftp db telegram
dcg up -d backup

step "Waiting for the backup to finish (the report arrives via Telegram)"
check "The backup reported success via Telegram" wait_for_message "Backup: Successful" 180
check "The database export reported success via Telegram" has "postgres: Successful"
check "No failure was reported" no_failure_reported
check "The configured comment appears in the report" has "comment: e2e"

step "Disaster recovery, part 1: fetching the latest snapshot back from the SFTP server"
dcg run --rm -T backup restore latest --target /restore >/dev/null
check "The restored database dump contains the original row" restored_dump_has_original_data

step "Disaster recovery, part 2: the data is lost in the database, then re-imported from the restored dump"
psql "DELETE FROM example_table" >/dev/null
check "The table is empty (data loss simulated)" table_is_empty
dc run --rm -T --entrypoint bash backup -c postgres_restore.sh >/dev/null 2>&1 || fail "The restore script finished without error"
pass "The restore script finished without error"
check "The original row is back in the database" original_row_is_back

# ---------------------------------------------------------------------------
scenario "2 - Unstable connection (Starlink mode): backup server is unreachable when the container starts"

step "The SFTP server is frozen, then the backup container starts in Starlink mode"
: > "$W/telegram/messages.log"
dc rm -sf backup >/dev/null
dc pause sftp
export STARLINK_MODE=true
dcg up -d --no-deps backup
sleep 25

step "The SFTP server becomes reachable again, the backup has to recover on its own"
dc unpause sftp
check "The backup finished successfully after the outage" wait_for_message "Backup: Successful" 240
logs=$(dc logs --no-color backup)
check "Starlink mode was active" grep -q "Starlink mode: enabled" <<< "$logs"
check "The container retried reaching the server instead of giving up" grep -q "ssh-keyscan for sftp failed" <<< "$logs"
check "No failure was reported" no_failure_reported

# ---------------------------------------------------------------------------
printf '\n%s%s\n E2E OK - %d checks passed%s\n' "$G" "$LINE" "${#PASSED[@]}" "$N"
printf '   - %s\n' "${PASSED[@]}"
