#!/usr/bin/env bats

load 'bats/bats-support/load'
load 'bats/bats-assert/load'
load 'helpers/setup'

setup_file() {
  # Clean state
  clean_restic_repo
  clean_volumes

  # Initialize SSH and prepare the backup container
  init_backup_env

  # Wait for postgres
  wait_for_healthy postgres 60
}

teardown_file() {
  clean_restic_repo
  clean_volumes
}

@test "postgres: seed data exists" {
  run run_backup_cmd 'PGPASSWORD="$POSTGRES_PASSWORD" psql -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -t -c "SELECT count(*) FROM example_table;"'
  assert_success
  local count
  count=$(echo "$output" | tr -d ' \n\r')
  [ "$count" -ge 1 ]
}

@test "postgres: insert test row" {
  run run_backup_cmd 'PGPASSWORD="$POSTGRES_PASSWORD" psql -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -c "INSERT INTO example_table (name) VALUES ('"'"'E2E Test Row'"'"');"'
  assert_success
}

@test "postgres: run postgres_backup.sh" {
  run run_backup_cmd 'postgres_backup.sh'
  assert_success
  assert_output --partial "DONE"
}

@test "postgres: verify dump file exists" {
  run run_in_backup 'test -f /source/backup.dump'
  assert_success
}

@test "postgres: run backup.sh to backup dump to restic" {
  run run_backup_cmd 'backup.sh'
  assert_success
  assert_output --partial "DONE"
}

@test "postgres: delete test row from database" {
  run run_backup_cmd 'PGPASSWORD="$POSTGRES_PASSWORD" psql -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -c "DELETE FROM example_table WHERE name='"'"'E2E Test Row'"'"';"'
  assert_success
}

@test "postgres: verify test row is gone" {
  run run_backup_cmd 'PGPASSWORD="$POSTGRES_PASSWORD" psql -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -t -c "SELECT count(*) FROM example_table WHERE name='"'"'E2E Test Row'"'"';"'
  assert_success
  local count
  count=$(echo "$output" | tr -d ' \n\r')
  [ "$count" -eq 0 ]
}

@test "postgres: restore from restic" {
  run run_backup_cmd 'restic restore latest --target /restore'
  assert_success
}

@test "postgres: run postgres_restore.sh" {
  run run_backup_cmd 'PGPASSWORD="$POSTGRES_PASSWORD" pg_restore --clean --if-exists -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" /restore/source/backup.dump || true'
  assert_success
}

@test "postgres: verify test row is restored" {
  run run_backup_cmd 'PGPASSWORD="$POSTGRES_PASSWORD" psql -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -t -c "SELECT count(*) FROM example_table WHERE name='"'"'E2E Test Row'"'"';"'
  assert_success
  local count
  count=$(echo "$output" | tr -d ' \n\r')
  [ "$count" -eq 1 ]
}
