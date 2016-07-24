#! /bin/bash
clear
export LANG=en_US
export LC_ALL=en_US.UTF-8
LOG_PATH=/root/log
TIME=`date | cut -d " " -f 4`
LOG_NAME=$LOG_PATH/connections-$TIME.log

CON_NEW=$(netstat -s | grep 'active connections openings' | awk '{print $1}')
CON2_NEW=$(netstat -s | grep 'passive connection openings' | awk '{print $1}')


while : ;
do
    echo -e "active connections:$CON_NEW, delta $[CON_NEW - CON]
    \npassive connections:$CON2_NEW, delta $[CON2_NEW - CON2]
    \n`netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'` ";
    sleep 1;
    CON=$CON_NEW;
    CON2=$CON2_NEW;
    CON_NEW=$(netstat -s | grep 'active connections openings' | awk '{print $1}')
    CON2_NEW=$(netstat -s | grep 'passive connection openings' | awk '{print $1}')
    clear;
done 


