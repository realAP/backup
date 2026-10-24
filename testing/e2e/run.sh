#!/usr/bin/env bash
# E2E: postgres -> backup image -> sftp, restore and compare. Same call locally and in the pipeline.
#   ./testing/e2e/run.sh          run everything, clean up afterwards
#   KEEP=1 ./testing/e2e/run.sh   leave the stack running for debugging
set -euo pipefail
cd "$(dirname "$0")"

W=.work
dc() { docker compose -p backup-e2e -f compose.yaml "$@"; }
has() { local m; m=$(msgs); grep -q "$1" <<< "$m"; }
msgs() { cat "$W/telegram/messages.log" 2>/dev/null || true; }
fail() { echo "FAIL: $*"; dc logs --no-color backup | tail -60; echo "--- telegram ---"; msgs; exit 1; }

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

rm -rf "$W" && mkdir -p "$W/telegram"
ssh-keygen -q -t ed25519 -N '' -f "$W/id"
cp "$W/id.pub" "$W/id.pub.tmp" && mv "$W/id.pub.tmp" "$W/id.pub"
chmod 644 "$W/id.pub"
SSH_PRIVATE_KEY_BASE64=$(base64 -w0 < "$W/id")
export SSH_PRIVATE_KEY_BASE64

dc down -v --remove-orphans >/dev/null 2>&1 || true
[[ -n "${SKIP_BUILD:-}" ]] || dc build backup

echo "### scenario 1: default mode, postgres -> sftp"
export STARLINK_MODE=false
dc up -d sftp db telegram
dc up -d backup
wait_for_message "Backup: Successful" 180 || fail "no 'Backup: Successful' message"
has "postgres: Successful" || fail "no 'postgres: Successful' message"
! has "Failure" || fail "a failure was reported"
has "comment: e2e" || fail "telegram comment missing"

echo "### restore and compare"
dc run --rm -T backup restore latest --target /restore >/dev/null
dc run --rm -T --entrypoint bash backup -c \
  'pg_restore -f - /restore/source/backup.dump | grep -q "Sample Data"' \
  || fail "restored dump does not contain the preset data"

echo "### re-import into postgres"
psql() { dc exec -T db psql -U user -d database -tA -c "$1"; }
psql "DELETE FROM example_table" >/dev/null
[[ "$(psql "SELECT count(*) FROM example_table")" == "0" ]] || fail "could not empty the table"
dc run --rm -T --entrypoint bash backup -c postgres_restore.sh >/dev/null 2>&1 || fail "postgres_restore.sh failed"
[[ "$(psql "SELECT name FROM example_table")" == "Sample Data" ]] || fail "data not back in postgres after restore"

echo "### scenario 2: starlink mode, target unreachable at start"
: > "$W/telegram/messages.log"
dc rm -sf backup >/dev/null
dc pause sftp
export STARLINK_MODE=true
dc up -d --no-deps backup
sleep 25
dc unpause sftp
wait_for_message "Backup: Successful" 240 || fail "starlink run did not recover"
logs=$(dc logs --no-color backup)
grep -q "ssh-keyscan for sftp failed" <<< "$logs" || fail "keyscan retry did not happen"
grep -q "Starlink mode: enabled" <<< "$logs" || fail "starlink mode not active"
! has "Failure" || fail "a failure was reported"

echo "E2E OK"
