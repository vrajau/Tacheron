#!/bin/bash


source ${BASH_SOURCE%/*}/settings.sh
set -f # We cannot man settings

##############################
#                            #
#        FUNCTIONS           #
#                            #
##############################


init()
{
  if [ ! -d "$TASKUSER" ];then
    $(mkdir $TASKUSER)
  fi

  if [ ! -f "$TASKGENERAL" ];then
    $(touch $TASKGENERAL)
  fi
}

initTacheron()
{
  init
  if [ ! -f "$LOG" ];then
    $(groupadd tacheron) 2>/dev/null
    $(touch $LOG)
    $(chown :tacheron $LOG)
    $(chmod 660 $LOG)
  fi

  if [ ! -f "$WHITELIST" ];then
    $(touch $WHITELIST)
    $(chown :tacheron $WHITELIST)
  fi

}


checkConfiguration(){
  if [ ! -f "$LOG" -o ! -f "$WHITELIST"  -o ! -f $TASKGENERAL ];then
    echo false
  else
    echo true
  fi
}



isValidField(){
  echo $(echo "$1"| awk 'NF>=7{print $1}')
}


analyseAndExecute(){

  #The second parser is very specific
  second=$(secondParser $(getFieldType "$1") $(convertSecond "$1") $(date +%S))
  minute=$(generalParser $(getFieldType "$2") "$2" $(date +%M) 0 59)
  hour=$(generalParser $(getFieldType "$3") "$3" $(date +%H) 0 23)
  dayMonth=$(generalParser $(getFieldType "$4") "$4" $(date +%d) 1 31)
  month=$(generalParser $(getFieldType "$5") "$5" $(date +%m) 1 12)
  dayWeek=$(generalParser $(getFieldType "$6") "$6" $(date +%w) 0 6)




  if [ "$second" = true ] && [ "$minute" = true ] && [ "$hour" = true ] && [ "$dayMonth" = true ] && [ "$month" = true ] && [ "$dayWeek" = true ];then
    log "Command $7 was executed"
    echo "-------------------------------"
    echo "RESULT"
    echo "-------------------------------"
    #Make sure that if the command is not valid it will not output to terminal
    $7 2>/dev/null
  fi

}


getFieldType()
{

  if  [[ "$1" =~ ^[[:digit:]]+$ ]];then
    echo "classic"
  elif [[ "$1" =~ ^([[:digit:]]+(,[[:digit:]]+)+)$ ]];then
    echo "virgule"
  elif [[ "$1" =~ ^[[:digit:]]+-[[:digit:]]+(~[[:digit:]]+)*$ ]];then
    echo "intervalle"
  elif [[ "$1" =~ ^(\*\/([[:digit:]]+))$ ]];then
    echo "all_regulier"
  elif [[ "$1" =~ ^(([[:digit:]]+-[[:digit:]]+(~[[:digit:]]+)*)\/([[:digit:]]+)) ]];then
    echo "intervalle_regulier"
  elif [[ "$1" == "*" ]];then
    echo "all"
  else
    echo "none"
  fi

}

convertSecond()
{
  echo $(echo "$1"|sed -e '{s/\b[1]\b/15/g;s/\b[2]\b/30/g;s/\b[3]\b/45/g}')
}


secondParser()
{
  case $1 in
    classic)
      echo $(classicSecondParser $2 $3)
      ;;
    virgule)
      echo $(virguleSecondParser $2 $3)
      ;;
    intervalle)
      echo $(intervalleSecondParser $2 $3)
      ;;
    all)
      echo $(allSecondParser $3)
      ;;
    esac
}

classicSecondParser()
{
  echo $(echo $1|awk -v var=$2 'var==$1 && var%15==0 {print "true"}')
}

virguleSecondParser(){
  echo $(echo $1|awk -F ',' -v var=$2 '{for(i=1;i<=NF;i++)if(var==$i && var%15==0){print "true"; break}}')
}

intervalleSecondParser()
{
  isValid=$(echo $1|sed -e 's/~/-/g'|awk -F '-' '{for(i=1;i<=NF;i++)if($i%15!=0 || $i>60){print "false"; break}}')
  if [ -z "$isValid" ];then
      read begin end <<< $(echo $1|awk -F '~' '{print $1}'|awk -F '-' '{print $1;print $2}')

    if [ "$begin" -lt "$end" ] && [ "$2" -ge "$begin" ] && [ "$2" -le "$end" ] && [ $(expr "$2" % 15) -eq 0 ];then
      notAllowed=$(echo $1|sed -e 's/[0-9]*-[0-9]*//g')
      isAllowed=$(echo $notAllowed|awk -F '~' -v var=$2 '{for(i=1;i<=NF;i++)if(var==$i){print "false"}}')

      if [ -z "$isAllowed" ];then
        echo "true"
      fi
    fi
  fi
}

allSecondParser()
{
  echo $(echo true|awk -v var=$1 '(var%15 == 0){print $0}')
}


generalParser()
{
  case $1 in
    classic)
      echo $(classicGeneralParser $2 $3)
      ;;
    virgule)
      echo $(virguleGeneralParser $2 $3)
      ;;
    intervalle)
      echo $(intervalleGeneralParser $2 $3 $4 $5)
      ;;
    intervalle_regulier)
      echo $(regintervalleGeneralParser $2 $3 $4 $5)
      ;;
    all_regulier)
      echo $(regAllGeneralParser $2 $3)
      ;;
    all)
      echo "true"
      ;;
    esac
}

classicGeneralParser()
{
  echo $(echo $1|awk -v var=$2 'var==$1 {print "true"}')
}

virguleGeneralParser()
{
  echo $(echo $1|awk -F ',' -v var=$2 '{for(i=1;i<=NF;i++)if(var==$i){print "true"; break}}')
}

intervalleGeneralParser()
{
  #Check if interval value are valid
  validIntervalle=$(echo $1|sed -e 's/~/-/g'|awk -F '-' -v begin=$3 -v end=$4 '{for(i=1;i<=NF;i++)if($i<begin || $i>end){print "false"; break}}')

  if [ -z "$validIntervalle" ];then
    read begin end <<< $(echo $1|awk -F '~' '{print $1}'|awk -F '-' '{print $1;print $2}')

    if [ "$begin" -lt "$end" ] && [ "$2" -ge "$begin" ] && [ "$2" -le "$end" ];then
      valueNotAllowed=$(echo $1|sed -e 's/[0-9]*-[0-9]*//g')
      isAllowed=$(echo $valueNotAllowed|awk -F '~' -v var=$2 '{for(i=1;i<=NF;i++)if(var==$i){print "false"}}')

      if [ -z "$isAllowed" ];then
        echo "true"
      fi
    fi
  fi
}


regintervalleGeneralParser()
{
  intervalle=$(echo $1| awk -F '/' '{print $1}')
  determinant=$(echo "$1"| awk -F '/' -v date=$2 'date%$2==0{print "true"}')

  if [ "$(intervalleGeneralParser "$intervalle" $2 $3 $4)" = true ] && [ "$determinant" = true ];then
    echo "true"
  fi
}

regAllGeneralParser()
{
  determinant=$(echo "$1"| awk -F '/' -v date=$2 'date%$2==0{print "true"}')
  if [ "$determinant" = true ];then
    echo "true"
  fi
}



log()
{
    date=$(date +%c)
    echo "$date : $1">>$LOG
    echo "$1">&1
}

checkUserId()
{
  $(id -u $1>/dev/null 2>&1)
  echo $? #Return 0 if user exist, else 1
}

checkUserGroup()
{
  $(groups $1| grep -q "\btacheron\b")
  echo $? #Return 0 if match, else 1
}

allowAccess()
{

  while read line;do
    if [ $(checkUserId "$line") -eq 0 ] && [ $(checkUserGroup $line) -eq 1 ];then
      log "User $line was added to list of Tacheron user"
      $(usermod -a -G tacheron $line)
    fi
  done < $WHITELIST
}


executeTask()
{
  while read task;do

    if [ ! -z $(isValidField "$task") ];then
      timeField=$(echo $task|awk '{for(i=1;i<=6;i++) print $i}')
      commande=$(echo $task|awk '{for(i=7;i<=NF;i++) print $i}')
      analyseAndExecute $timeField "$commande"
    fi
  done < $1
}



##############################
#                            #
#        PROCESSUS           #
#                            #
##############################

currentUser=$(whoami)
config=$(checkConfiguration)


#Check if config file are initialized correctly
if [ "$config" = false ] && [ "$EUID" -eq 0 ];then
  initTacheron
  log "Tacheron was succesfully initialized">&1
elif [ "$config" = true ] && [ "$EUID" -eq 0 ];then
  allowAccess
elif [ "$config" = false ];then
  echo "When this is your first time running Tacheron, you must run the command as root user">&2
  exit 1
fi


if [ "$EUID" -eq 0 ] || [ $(checkUserGroup $currentUser) -eq 0 ];then
  log "$currentUser started Tacheron"
  while true;
  do
    executeTask $TASKGENERAL
    if [ -f "$TASKUSER/tacherontab$currentUser" ];then
      executeTask "$TASKUSER/tacherontab$currentUser"
    fi
      $(sleep 0.7)
  done
else
  echo "You are not allowed to use Tacheron. Contact your administrator">&2
  exit 1
fi
