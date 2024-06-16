# backup
How to make a backup with nextcloud, restic and hetzner storagebox and use telegram as notification service. All of it in a container based manner.

# Overview
![backup_overview.drawio.svg](backup_overview.drawio.svg)


# General
As seen in the overview picture above, the whole logic is container based.
This aspect is used to operate in two different modes.
1. Default mode is running the script without any arguments.
    * e.g. `./run_backup.sh`
1. Argument mode. Use the script as you would use restic. The script will run the container in which restic is started and places every argument behind it.
You have access to all the environment variables set in the `.env` file.
      * `./run_backup.sh snapshots`
      * `./run_backup.sh init`
      * and more...

# Beginning
## Create Repository

## Run Backup

# Restore data

---
# Debugging

# Logging

# ToDo

# Why | Motivation

