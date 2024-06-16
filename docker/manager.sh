#!/usr/bin/bash

nextcloudLastLogfile="/var/log/nextcloud-last.log"
backupLastLogfile="/var/log/backup-last.log"

nextcloud.sh &> ${nextcloudLastLogfile}
status_nextcloud=$?
backup.sh &> ${backupLastLogfile}
status_backup=$?

telegram.sh ${nextcloudLastLogfile}
telegram.sh ${backupLastLogfile}

if [[ $status_nextcloud == 0 ]]; then
  telegram.sh "Nextcloud: Successfull"
else
  telegram.sh "Nextcloud: Failure"
fi

if [[ $status_backup == 0 ]]; then
  telegram.sh "Backup Successfull"
else
  telegram.sh "Backup: Failure"
fi
