#!/bin/bash -l
set -e
echo "----------- START NEXTCLOUD CLIENT -----------"
nextcloudcmd --non-interactive --silent -u $NC_USER -p "$NC_PASS" /source/nextcloud $NC_URL
echo "----------- END NEXTCLOUD CLIENT -----------"
