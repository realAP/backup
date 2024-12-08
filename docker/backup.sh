#!/usr/bin/env bash
set -e
echo "=========LET'S DO THIS, BACKUP THE SHIT!!!========="
date
hasRepo="restic cat config"
$hasRepo || restic init || exit 1

echo "+------------------------------------------+"
echo "|::::::::::::::::call backup:::::::::::::::|"
echo "+------------------------------------------+"
restic backup /source

echo "+------------------------------------------+"
echo "|::::::::::::::::call check::::::::::::::::|"
echo "+------------------------------------------+"
restic check

echo "+------------------------------------------+"
echo "|::::::::::::::::call forget:::::::::::::::|"
echo "+------------------------------------------+"
restic forget --keep-weekly 52 --keep-monthly 12 --keep-yearly 100

echo "+------------------------------------------+"
echo "|::::::::::::::::call check::::::::::::::::|"
echo "+------------------------------------------+"
restic check
echo "==================DONE====================="
