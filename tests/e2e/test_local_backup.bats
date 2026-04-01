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
}

teardown_file() {
  clean_restic_repo
  clean_volumes
}

@test "backup: copy test files to /source" {
  run_in_backup 'cp -r /test_data/* /source/'
  run run_in_backup 'ls /source/file1.txt /source/file2.txt /source/subdir/file3.txt'
  assert_success
}

@test "backup: compute checksums of source files" {
  run run_backup_cmd 'sha256sum /source/file1.txt /source/file2.txt /source/subdir/file3.txt | tee /tmp/checksums_original.txt'
  assert_success
}

@test "backup: run backup.sh to create restic backup" {
  run run_backup_cmd 'backup.sh'
  assert_success
  assert_output --partial "DONE"
}

@test "backup: verify restic snapshots exist" {
  run run_backup_cmd 'restic snapshots'
  assert_success
  assert_output --partial "snapshot"
}

@test "restore: clear /source to prove restore works from backup" {
  run run_in_backup 'rm -rf /source/*'
  assert_success
  # Verify source is empty
  run run_in_backup 'ls /source/'
  assert_output ""
}

@test "restore: restore latest snapshot" {
  run run_backup_cmd 'restic restore latest --target /restore'
  assert_success
  assert_output --partial "restoring"
}

@test "restore: verify restored files exist" {
  run run_in_backup 'ls /restore/source/file1.txt /restore/source/file2.txt /restore/source/subdir/file3.txt'
  assert_success
}

@test "restore: verify restored file checksums match originals" {
  # Recompute checksums from test_data (the original source)
  run run_in_backup '
    sha256sum /test_data/file1.txt /test_data/file2.txt /test_data/subdir/file3.txt | awk "{print \$1}" | sort > /tmp/expected.txt
    sha256sum /restore/source/file1.txt /restore/source/file2.txt /restore/source/subdir/file3.txt | awk "{print \$1}" | sort > /tmp/actual.txt
    diff /tmp/expected.txt /tmp/actual.txt
  '
  assert_success
}

@test "restic: repository check passes" {
  run run_backup_cmd 'restic check'
  assert_success
  assert_output --partial "no errors were found"
}
