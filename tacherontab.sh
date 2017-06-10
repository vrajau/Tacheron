#!/bin/bash

source functions/tacherontabFunctions.sh

if [ "$EUID" -eq 0 ];then
  init #initialize folder
  user=""
  while getopts "u:rel" option; do
    case $option in
      u)
        if [ $(checkUserId $OPTARG ) -eq 0 ];then
          user=$OPTARG
        else
          echo "The specified user does not exist. Tacherontab is going to use general configuration">&2
        fi
        ;;
      l)
        displayFile $(selectConfig $user)
        ;;
      e)
        createOrModify $(selectConfig $user)
        ;;
      r)
        deleteFile $(selectConfig $user)
        ;;
      esac
    done
else
  echo "You must be root user to use tacherontab command">&2
fi
