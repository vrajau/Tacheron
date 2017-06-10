#!/bin/bash


source settings.sh

init()
{
  if [ ! -d $CONFIGUSER ];then
    $(mkdir $CONFIGUSER)
  fi

  if [ ! -f $CONFIGALL ];then
    $(touch $CONFIGALL)
  fi
}


checkUserId()
{
  test=$(id -u $1>/dev/null 2>&1)
  echo $? #Return 0 if user exist, else 1
}

#Select the proper config to check if it's general config or user config
selectConfig()
{
  configFile=$CONFIGALL
  if [ ! -z $1 ];then
    configFile=$CONFIGUSER"tacherontab"$1
  fi
  echo $configFile
}
