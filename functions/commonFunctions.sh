#!/bin/bash

#Initialize by creating needed file
init()
{
  if [ ! -d "$CONFIGUSER" ];then
    $(mkdir $CONFIGUSER)
  fi

  if [ ! -f "$CONFIGALL" ];then
    $(touch $CONFIGALL)
  fi
}
