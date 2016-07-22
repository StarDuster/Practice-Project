#! /bin/bash
clear
export LANG=en_US
export LC_ALL=en_US.UTF-8
LOG_PATH=/root/log

CHECK_OK=0

function check()
{
    if echo $1 | egrep -q '^[0-9]+$'; then :
    else echo -e "\nthe $1 is not a valid input!\n" && CHECK_OK=1;
    fi
}

function run_test() 
{
    TIME=`date | cut -d " " -f 4`

    echo -e "\nnow is $TIME \n"
    read -p "input the concurrency:" CON
    read -p "input the total requests:" REQ
    read -p "how many ab process do you want to run?" PROCESS_NUM
    read -p "http or https,1 is for http,2 is for https,default is http:" IF_HTTPS
    if [ "$IF_HTTPS" = "" ];then
        IF_HTTPS=1
    fi
    if [ "$IF_HTTPS" = "1" ];then
        PROTOCOL=http
    elif [ "$IF_HTTPS" = "2" ];then
        PROTOCOL=https
    else    
        echo "input error" && exit 1
    fi

#check input    
    for var in $CON $REQ $PROCESS_NUM;
    do
        check $var;
    done

#something else can be added to the log file name:
    read -p "enable keep-alive connection? 1 is for yes,2 is for no,default is no:" IF_LONG
    if [ "$IF_LONG" = "" ];then
        IF_LONG=2
    fi
  
    read -p "input the lable of this test,press enter for none:" TAG
    if [ "$TAG" = "" ];then :
    else TAG=$TAG-
    fi

    if [ "$CHECK_OK" = "0"  ];then
        echo -e "testing...logging to $LOG_PATH/ \n"
        for (( i=1; i<$[PROCESS_NUM+1]; i=i+1 )); do
            LOG_NAME=$LOG_PATH/$PROTOCOL-$REQ@$CON-$TAG$TIME-$i-of-$PROCESS_NUM.log
            ab -s 120 -r -n $REQ -c $CON $PROTOCOL://test.starduster.me/  > $LOG_NAME &  
            #tee - $LOG_NAME
        done
        wait
    else echo -e "\nCheck fail!\n" && exit 1;
    fi
}

#entrance of this script:
run_test
