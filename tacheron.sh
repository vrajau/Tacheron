#!/bin/bash

source functions/tacheronFunctions.sh
set -f # We cannot man settings
currentUser=$(whoami)
config=$(checkConfiguration)


#Check if config file are initialized correctly
if [ "$config" = false ] && [ "$EUID" -eq 0 ];then
  initTacheron
  echo "Tacheron was succesfully initialized"
elif [ "$config" = false ];then
  echo "When this is your first time running Tacheron, you must run the command as root user">&2
  exit 1
fi


if [ "$EUID" -eq 0 ] || [ $(isUserAllowed $currentUser) = true ];then
  while true;
  do
      while read task;do
        if [ ! -z $(validField "$task") ];then
          timeField=$(echo $task|awk '{for(i=1;i<=6;i++) print $i}')
          commande=$(echo $task|awk '{for(i=7;i<=NF;i++) print $i}')
           analyseAndExecute $timeField "$commande"
        fi
      done < $CONFIGALL
      $(sleep 0.7)
  done
else
  echo "You are not allowed to use Tacheron. Contact your administrator">&2
  exit 1
fi
