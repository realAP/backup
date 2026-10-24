#!/usr/bin/env bash
# Shared connection tuning. Sourced by prepare_ssh.sh and backup.sh.
#
# Every variable here is optional. With none of them set the behaviour is
# identical to the versions before the starlink option existed.

# STARLINK_MODE is a switch which only picks sane defaults for links that drop
# the TCP connection regularly (satellite handover, changing public IP, weak
# uplink). Single variables can still be overridden on top of it.
starlink_enabled=0
case "${STARLINK_MODE,,}" in
  true | 1 | yes | on) starlink_enabled=1 ;;
esac

if [[ ${starlink_enabled} -eq 1 ]]; then
  : "${BACKUP_CONNECTIONS:=2}"
  : "${BACKUP_LOCK_RETRY:=15m}"
  : "${BACKUP_RETRIES:=5}"
  : "${BACKUP_RETRY_DELAY:=60}"
else
  : "${BACKUP_RETRIES:=1}"
  : "${BACKUP_RETRY_DELAY:=60}"
fi
