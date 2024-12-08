[![Pipeline](https://github.com/realAP/backup/actions/workflows/pipeline.yml/badge.svg?branch=main)](https://github.com/realAP/backup/actions/workflows/pipeline.yml)
[![Docker Image Version](https://img.shields.io/docker/v/devp1337/backup?sort=semver)](https://hub.docker.com/r/devp1337/backup)

### Version: 1.1.0

# backup
Use this image to load your data from a **provider** into your **binded** folder. This folder will be used as input for restic. Restic creates a backup and upload it to your sftp host.
All of it in a container based manner.

# Overview
![backup_overview.drawio.svg](resources/backup_overview.svg)

# General
There are two modes.
1. Default mode is running the script without any arguments.
    * e.g. `./run_backup.sh`
1. Argument mode. Use the script as you would use restic. The script will run the container in which restic is started and places every argument behind it.
You have access to all the environment variables set in the `.env` file.
      * `./run_backup.sh snapshots`
      * `./run_backup.sh init`
      * and more...

# How to use it
### Prerequisite
These things are needed:
* Nextcloud Server
* SFTP Server
* Docker
* a device where the backup is running

Place your public key at the sftp server and use the private key to log into it.
> Currently, the private key should not have a password, it is not supported yet.
> This is not ideal, in further versions private key with passwords are supported and recommended to use.

### Build image
1. clone the repository `https://github.com/realAP/backup.git`
1. `cd backup/docker` 
1. build the docker image `docker build . -t restic`

### Set .env file
Fill all variables in the `.env` file, it is provided with example values.

### Create Repository
In first place a repository has to be created on the remote (sftp).

1. `./run_backup.sh init` this will initialize a repository
1. exit the container 

### Run Backup
Just run the script `./run_backup.sh` it will immediately sync the nextcloud and creates a backup, the status report will be sent via telegram.
This repeats every day at 1am (default), feel free to adjust the `cron` variable in the run_backup.sh

# Restore data
Just work as you would do it with restic.
When cloned the repo there is an empty folder called `restore` which is mounted into the container under /restore.
This folder can be used as target for your restored data.
Example: to get the latest snapshot from your data
`./run_backup.sh restore latest --target /restore`

---
# Debugging
The `run_backup.sh` has a flag 
* `"DEBUG"=0` which disables
* `"DEBUG"=1` which enables debugging
  * the container will start and opens a bash terminal

# Logging
The `log` folder is mounted to `/var/log` which enables to have access to different kinds of log files.

# ToDo
TBD

# Why | Motivation
I have used https://duplicati.com/ which i can recommend. 
My problem is duplicati is not supported for my hardware anymore.
This is the reason for this project.

I have nextcloud hosted by hetzner (https://www.hetzner.com/storage/storage-share/) and storagebox (https://www.hetzner.com/storage/storage-box/) a sftp hosted platform.
The backup should work without hetzner it just needs a nextcloud server and sftp access.
