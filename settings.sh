#!/bin/bash

#Constant used by each command

#The directory containing the config file for each user
declare -r TASKUSER="/etc/tacheron/"
#The config file for every user
declare -r TASKGENERAL="/etc/tacherontab"
#Temporary file created to be added to either the general config file or user config file
declare -r TEMPFILE="/tmp/tacherontabtempfile"
#The log file
declare -r LOG="/var/log/tacheron"
#List of user allowed to use tacheron command
declare -r WHITELIST="/etc/tacheron.allow"
