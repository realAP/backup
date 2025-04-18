#!/usr/bin/bash

provisionLastLogfile="/var/log/provision-last.log"
backupLastLogfile="/var/log/backup-last.log"

telegram.sh "hostname: $(hostname)"
telegram.sh "comment: ${comment}"

# check which provision mode to execute
if [[ "$PROVISION_MODE" == "nextcloud" ]]; then
  nextcloud.sh 2>&1 | tee ${provisionLastLogfile}
  status_provision=$?
fi
if [[ "$PROVISION_MODE" == "postgres" ]]; then
  postgres_backup.sh 2>&1 | tee ${provisionLastLogfile}
  status_provision=$?
fi

if [[ "$PROVISION_MODE" == "none" ]]; then
  echo "PROVISION_MODE is set to none." 2>&1 | tee ${provisionLastLogfile}
  # shellcheck disable=SC2320
  status_provision=$?
fi

backup.sh 2>&1 | cat | tee ${backupLastLogfile}
status_backup=$?

telegram.sh ${provisionLastLogfile}
telegram.sh ${backupLastLogfile}

if [[ $status_provision == 0 ]]; then
  telegram.sh "$PROVISION_MODE: Successful"
else
  telegram.sh "$PROVISION_MODE: Failure"
fi

if [[ $status_backup == 0 ]]; then
  telegram.sh "Backup: Successful"
else
  telegram.sh "Backup: Failure"
fi
