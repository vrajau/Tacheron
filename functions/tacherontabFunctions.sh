#!/bin/bash


source settings.sh
source functions/commonFunctions.sh



checkUserId()
{
  test=$(id -u $1>/dev/null 2>&1)
  echo $? #Return 0 if user exist, else 1
}

#Select the proper config to check if it's general config or user config
selectConfig()
{
  configFile=$CONFIGALL
  if [ ! -z "$1" ];then
    configFile=$CONFIGUSER"tacherontab"$1
  fi
  echo $configFile
}

displayFile()
{
  if [ -f "$1" ];then
     cat $1
  else
    echo "The file $1 does not exist. Please create it with option -e"
  fi
}

createOrModify()
{
  $(touch $TEMPFILE )
  vi $TEMPFILE
  $(cat $TEMPFILE >> $1 )
  $(rm -f $TEMPFILE)
}


deleteFile()
{
  if [ "$1" == "$CONFIGALL" ];then
    #If this is general configuration, no need to delete file
    #Most efficient method to delete content of file
     $(truncate -s 0 $1)
     echo "Deleted $1 content successfully"
  else
    $(rm -f $1)
    echo "Erased $1 successfully "
  fi
}
