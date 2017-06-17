#!/bin/bash

source ${BASH_SOURCE%/*}/settings.sh

##############################
#                            #
#        FUNCTIONS           #
#                            #
##############################


init()
{
  if [ ! -d "$TASKUSER" ];then
    $(mkdir $TASKUSER)
    $(chmod -R 777 $TASKUSER)
  fi

  if [ ! -f "$TASKGENERAL" ];then
    $(touch $TASKGENERAL)
  fi
}

checkConfiguration(){
  if [ ! -d "$TASKUSER" -o ! -f "$TASKGENERAL" ];then
    echo false
  else
    echo true
  fi
}


checkUserId()
{
  $(id -u $1>/dev/null 2>&1)
  echo $? #Return 0 if user exist, else 1
}

#Select the proper config to check if it's general config or user config
selectConfig()
{

  if [ "$EUID" -eq 0 ] && [ "$1" == "root" ];then
    configFile=$TASKGENERAL
  elif [ "$EUID" -ne 0 ] && [ "$1" == "root" -o "$1" != "$2"  ];then
    echo "You cannot change someone else configuration, unless you are root">&2
    exit 1
  else
    configFile=$TASKUSER"tacherontab"$1
  fi
  echo $configFile
}

displayFile()
{
  if [ -f "$1" ];then
     cat $1
  else
    echo "The file $1 does not exist. Please create it with option -e">&2
    exit 1;
  fi
}

createOrModify()
{
  $(touch $TEMPFILE )
  if [ -f "$1" ];then
    $(cat $1 > $TEMPFILE)
  fi

  vi $TEMPFILE
  $(cat $TEMPFILE > $1 )
  $(rm -f $TEMPFILE)
  giveAccess $2 $1
}

giveAccess()
{
  if [ "$EUID" -eq 0 ];then
    $(chown $1:$1 $2)
  fi
}


deleteFile()
{
  if [ "$1" == "$TASKGENERAL" ];then
    #If this is general configuration, no need to delete file
    #Most efficient method to delete content of file
     $(truncate -s 0 $1)
     echo "Deleted $1 content successfully"
  else
    $(rm -f $1)
    echo "Erased $1 successfully "
  fi
}

##############################
#                            #
#        PROCESSUS           #
#                            #
##############################



if [ $(checkConfiguration) = false ] && [ "$EUID" -eq 0 ];then
  init
elif [ $(checkConfiguration) = false ];then
  echo "This is your first time running Tacherontab, you must be root user">&2
fi

if [ $(checkConfiguration) = true ];then
  user=$(whoami)
  currentUser=$(whoami)
  while getopts "u:rel" option; do
    case $option in
      u)
        if [ $(checkUserId $OPTARG ) -eq 0 ];then
          user=$OPTARG
        else
          echo "The specified user does not exist.">&2
          exit 1;
        fi
        ;;
      l)
        displayFile  $(selectConfig $user $currentUser)
        ;;
      e)
        createOrModify $(selectConfig $user $currentUser) $user

        ;;
      r)
        deleteFile $(selectConfig $user $currentUser)
        ;;
      esac
    done
fi
