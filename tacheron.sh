#!/bin/bash

source functions/tacheronFunctions.sh
currentUser=$(whoami)
config=$(checkConfiguration)


if [ "$config" = false ] && [ "$EUID" -eq 0 ];then
  initTacheron
  echo "Tacheron was succesfully initialized"
  config=$(checkConfiguration)
else
  echo "When this is your first time running Tacheron, you must run the command as root user">&2
  exit 1
fi
