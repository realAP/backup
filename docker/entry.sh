#!/bin/bash -l

##### CONECTION SPECIFIC FOR REMOTE HOST
# ssh specific
# makes an entry into known hosts so it will not stop at prompt
ssh-keyscan -t rsa $TARGET_DOMAIN > /etc/ssh/ssh_known_hosts
# create ssh config for easier access in backup.sh
create_ssh_config.sh

# https://stackoverflow.com/a/48651061
# is needed to save the container environment variables which for later usage from script for cron jobs
export RESTIC_REPOSITORY=sftp:storagebox:${RESTIC_REPOSITORY_NAME}
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

# argument mode
if [[ "$#" > 0 ]]; then
  restic $@
else
# default mode
  manager.sh
  cron -f 
fi
