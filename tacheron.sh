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
  if [ ! -d "$CONFIGUSER" ];then
    $(mkdir $CONFIGUSER)
  fi

  if [ ! -f "$CONFIGALL" ];then
    $(touch $CONFIGALL)
  fi
}

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
    $7
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
  elif [[ "$1" == "*" ]];then
    echo "all"
  else
    echo "none"
  fi

}


convertSecond()
{
  echo $(echo "$1"|sed -e '{s/[1]/15/g;s/[3]/45/g;s/[2]/30/g}')
}


secondParser()
{

  case $1 in
    classic)
      echo $(echo $2|awk -v var=$3 'var==$1 {print "true"}')
      ;;
    virgule)
      echo $(echo $2|awk -F ',' -v var=$3 '{for(i=1;i<=NF;i++)if(var==$i){print "true"; break}}')
      ;;
    intervalle)
      #Let's check if all of those numbers are valid
      isValid=$(echo $2|sed -e 's/~/-/g'|awk -F '-' '{for(i=1;i<=NF;i++)if($i%15!=0 || $i>60){print "false"; break}}')
      if [ -z "$isValid" ];then
        read begin end <<< $(echo $2|awk -F '~' '{print $1}'|awk -F '-' '{print $1;print $2}')
        if [ "$begin" -lt "$end" ] && [ "$3" -ge "$begin" ] && [ "$3" -le "$end" ] && [ $(expr "$3" % 15) -eq 0 ];then
          notAllowed=$(echo $2|sed -e 's/[0-9]*-[0-9]*//g')
          isAllowed=$(echo $notAllowed|awk -F '~' -v var=$3 '{for(i=1;i<=NF;i++)if(var==$i){print "false"}}')
          if [ -z "$isAllowed" ];then
            echo "true"
          fi
        fi
      fi
      ;;
    all)
      echo $(echo true|awk -v var=$3 '(var%15 == 0){print $0}')
      ;;
    esac
}




generalParser(){
  case $1 in
    classic)
      echo $(echo $2|awk -v var=$3 'var==$1 {print "true"}')
      ;;
    virgule)
      echo $(echo $2|awk -F ',' -v var=$3 '{for(i=1;i<=NF;i++)if(var==$i){print "true"; break}}')
      ;;
    intervalle)
      #Let's check if all of those numbers are valid
      isValid=$(echo $2|sed -e 's/~/-/g'|awk -F '-' -v begin=$4 -v end=$5 '{for(i=1;i<=NF;i++)if($i<begin || $i>end){print "false"; break}}')
      if [ -z "$isValid" ];then
        read begin end <<< $(echo $2|awk -F '~' '{print $1}'|awk -F '-' '{print $1;print $2}')
        if [ "$begin" -lt "$end" ] && [ "$3" -ge "$begin" ] && [ "$3" -le "$end" ];then
          notAllowed=$(echo $2|sed -e 's/[0-9]*-[0-9]*//g')
          isAllowed=$(echo $notAllowed|awk -F '~' -v var=$3 '{for(i=1;i<=NF;i++)if(var==$i){print "false"}}')
          if [ -z "$isAllowed" ];then
            echo "true"
          fi
        fi
      fi
      ;;
    all)
      echo "true"
      ;;
    esac
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
  echo "Tacheron was succesfully initialized"
elif [ "$config" = false ];then
  echo "When this is your first time running Tacheron, you must run the command as root user">&2
  exit 1
fi


if [ "$EUID" -eq 0 ] || [ $(isUserAllowed $currentUser) = true ];then
  while true;
  do
      while read task;do
        if [ ! -z $(isValidField "$task") ];then
          timeField=$(echo $task|awk '{for(i=1;i<=6;i++) print $i}')
          commande=$(echo $task|awk '{for(i=7;i<=NF;i++) print $i}')
           analyseAndExecute $timeField "$commande"
        fi
      done < $CONFIGALL
      $(sleep 0.7)
  done
else
  echo "You are not allowed to use Tacheron. Contact your administrator">&2
  exit 1
fi
