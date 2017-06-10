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
  if [ ! -f "$LOG" -o ! -f "$WHITELIST"  -o ! -f $CONFIGALL ];then
    echo false
  else
    echo true
  fi
}


isUserAllowed(){
  isAllowed=false
  while read line; do
    if [ "$1" == "$line" ];then
      isAllowed=true
    fi
  done < $WHITELIST

  echo $isAllowed
}
