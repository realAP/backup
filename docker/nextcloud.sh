#!/usr/bin/env bash
set -e
mkdir -p /source/nextcloud
echo "----------- START NEXTCLOUD CLIENT -----------"
nextcloudcmd --non-interactive --silent -u $NC_USER -p "$NC_PASS" /source/nextcloud "$NC_URL"
echo "----------- END NEXTCLOUD CLIENT -----------"
