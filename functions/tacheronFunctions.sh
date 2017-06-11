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

analyseAndExecute(){
  testee="60-79000~17~18"
  # parseSecond=$(checkValues "$testee")
  parseMinute=$(checkValues "$testee")
  echo $parseMinute
  to=$(minuteParser $parseMinute "$testee")
  echo "$to"

}


validField(){
  echo $(echo "$1"| awk 'NF==7{print $1}')
}

checkValues()
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
  currentSecond=$(date +%S)
  second=$(convertSecond "$2")
  case $1 in
    classic)
      echo $(echo $second|awk -v var=$currentSecond 'var==$1 {print "true"}')
      ;;
    virgule)
      #We don't need to check if every values is correct or duplicate, we just check if current second
      #is allowed and we break the loop if it's the case. Save some time and work
      echo $(echo $second|awk -F ',' -v var=$currentSecond '{for(i=1;i<=NF;i++)if(var==$i){print "true"; break}}')
      ;;
    intervalle)
      #Let's check if all of those numbers are valid
      isValid=$(echo $second|sed -e 's/~/-/g'|awk -F '-' '{for(i=1;i<=NF;i++)if($i%15!=0 || $i>60){print "false"; break}}')
      if [ -z "$isValid" ];then
        read begin end <<< $(echo $second|awk -F '~' '{print $1}'|awk -F '-' '{print $1;print $2}')
        if [ "$begin" -lt "$end" ] && [ $currentSecond -ge $begin ] && [ $currentSecond -le $end ] && [ $(expr $currentSecond % 15) -eq 0 ];then
          notAllowed=$(echo $second|sed -e 's/[0-9]*-[0-9]*//g')
          isAllowed=$(echo $notAllowed|awk -F '~' -v var=$currentSecond '{for(i=1;i<=NF;i++)if(var==$i){print "false"}}')
          if [ -z "$isAllowed" ];then
            echo "true"
          fi
        fi
      fi

      ;;
    all)
      echo $(echo true|awk -v var=$currentSecond '(var%15 == 0){print $0}')
      ;;
    esac
}


minuteParser(){
  currentMinute=$(date +%M)
  case $1 in
    classic)
      echo $(echo $2|awk -v var=$currentMinute 'var==$1 {print "true"}')
      ;;
    virgule)
      #We don't need to check if every values is correct or duplicate, we just check if current second
      #is allowed and we break the loop if it's the case. Save some time and work
      echo $(echo $2|awk -F ',' -v var=$currentMinute '{for(i=1;i<=NF;i++)if(var==$i){print "true"; break}}')
      ;;
    intervalle)
      #Let's check if all of those numbers are valid
      isValid=$(echo $2|sed -e 's/~/-/g'|awk -F '-' '{for(i=1;i<=NF;i++)if($i<0 || $i>59){print "false"; break}}')
      if [ -z "$isValid" ];then
        read begin end <<< $(echo $2|awk -F '~' '{print $1}'|awk -F '-' '{print $1;print $2}')
        if [ "$begin" -lt "$end" ] && [ $currentMinute -ge $begin ] && [ $currentMinute -le $end ];then
          notAllowed=$(echo $2|sed -e 's/[0-9]*-[0-9]*//g')
          isAllowed=$(echo $notAllowed|awk -F '~' -v var=$currentMinute '{for(i=1;i<=NF;i++)if(var==$i){print "false"}}')
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
