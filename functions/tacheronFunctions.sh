#!/bin/bash

source settings.sh
source functions/commonFunctions.sh

initTacheron()
{
  init
  if [ ! -f "$LOG" ];then
    $(touch $LOG)
  fi

  if [ ! -f "$WHITELIST" ];then
    $(touch $WHITELIST)
  fi
}


checkConfiguration(){
  if [ ! -f "$LOG" -o ! -f "$WHITELIST" ];then
    echo false
  else
    echo true
  fi
}
