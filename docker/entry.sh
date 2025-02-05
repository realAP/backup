#!/bin/bash -l

# Build repository variable which is later used for restic to determine repo
export RESTIC_REPOSITORY=sftp:storagebox:${RESTIC_REPOSITORY_NAME}

prepare.sh

# https://stackoverflow.com/a/48651061
# is needed to save the container environment variables which for later usage from script for cron jobs
declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

#create crontab
# https://stackoverflow.com/a/47960145 comment section recommended the proc for cron output is usable for docker logs
(echo "
SHELL=/bin/bash
BASH_ENV=/container.env
$CRON manager.sh > /proc/1/fd/1 2> /proc/1/fd/2") | crontab -

if [[ "$DEBUG" == "1" ]];then
  echo "Debug mode enabled. Starting /bin/bash..."
  exec bin/bash 
fi

echo "TODO: REMOVE ME: CI/CD TESTING"

# argument mode
if [[ $# -gt 0 ]]; then
  restic "${@}"
else
# default mode for provisioning
  manager.sh
  cron -f 
fi
