#!/bin/bash


source settings.sh

init()
{
  if [ ! -d $CONFIGUSER ];then
    $(mkdir $CONFIGUSER)
  fi
}
