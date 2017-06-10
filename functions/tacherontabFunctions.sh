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
