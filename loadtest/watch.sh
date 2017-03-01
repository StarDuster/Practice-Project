#! /bin/bash
clear
export LANG=en_US
export LC_ALL=en_US.UTF-8
LOG_PATH=/root/log
TIME=`date | cut -d " " -f 4`
LOG_NAME=$LOG_PATH/connections-$TIME.log

CON_NEW=$(netstat -s | grep 'active connections openings' | awk '{print $1}')
COUNT=0
until [ $COUNT -eq 30 ];
do
    echo -e "active connections:$CON_NEW, delta $[CON_NEW - CON] 
    \n`netstat -i eth0 -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'` " | tee -a $LOG_NAME;
    sleep 1;
    CON=$CON_NEW;
    CON_NEW=$(netstat -s | grep 'active connections openings' | awk '{print $1}')
    clear;
    if [ "$CON" = "$CON_NEW" ]; then
        COUNT=$[COUNT+1];
    else
        COUNT=0;
    fi
done 

echo -e "connections lasts at $CON for 30s,exit\n"


