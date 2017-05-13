#!/bin/bash

source functions/tacherontabFunctions.sh

if [ $EUID -eq 0 ];then
  init
else
  echo "You must be root user to use tacherontab command">&2
fi
