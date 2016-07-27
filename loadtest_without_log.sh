#! /bin/bash
clear
export LANG=en_US
export LC_ALL=en_US.UTF-8
LOG_PATH=/root/log

function check()
{
    if echo $1 | egrep -q '^[0-9]+$'; then :
    else echo -e "\nThe input $1 is not a valid number!\n" && exit 1;
    fi
}

#the fuck shell cannot calculate float number
function calc()
{
    awk "BEGIN{print $*}";
}

function run_test()
{
    TIME=`date | cut -d " " -f 4`

    echo -e "\nnow is $TIME \n"
    read -p "input the concurrency:" CON
        check $CON;
    read -p "input the total requests:" REQ
        check $REQ;
    read -p "how many ab process do you want to run?" PROCESS_NUM
        if [ "$PROCESS_NUM" = "" ];then
                    PROCESS_NUM=1
        fi
        check $PROCESS_NUM;

    read -p "http or https,1 is for http,2 is for https,default is https:" IF_HTTPS
    if [ "$IF_HTTPS" = "" ];then
        IF_HTTPS=2
    fi
    if [ "$IF_HTTPS" = "1" ];then
        PROTOCOL=http
    elif [ "$IF_HTTPS" = "2" ];then
        PROTOCOL=https
    else
        echo "input error" && exit 1
    fi

#something else can be added to the log file name:
    read -p "enable keep-alive connection? 1 is for yes,2 is for no,default is no:" IF_LONG
    if [ "$IF_LONG" = "" ];then
        IF_LONG=2
    fi
    if [ "$IF_LONG" = "1" ];then
        LONG="-k"
    else
        LONG=""
    fi

    read -p "input the lable of this test,press enter for none:" TAG
    if [ "$TAG" = "" ];then :
    else TAG=$TAG-
    fi

    echo -e "testing...logging to $LOG_PATH/ \n"
        for (( i=1; i<$[PROCESS_NUM+1]; i=i+1 )); do
            LOG_NAME=$LOG_PATH/$PROTOCOL-$REQ@$CON-$TAG$TIME$LONG-$i-of-$PROCESS_NUM.log
            ab -s 120 -r $LONG -n $REQ -c $CON $PROTOCOL://test.starduster.me/  &
        done
    wait
    RUN_TIME=`cat $TMP | grep "Time taken" | awk '{print $5}'`
    COMPLETE_REQ=`cat $TMP | grep "Complete" | awk '{print $3}'`
    MEAN_TIME=`calc $COMPLETE_REQ/$RUN_TIME`
    echo -e "\ndone,the mean RPS is $MEAN_TIME\n"
}


#entrance of this script:
run_test
