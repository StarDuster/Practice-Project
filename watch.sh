clear
CON_NEW=$(netstat -s | grep 'active connections openings' | awk '{print $1}')
COUNT=0
until [ $COUNT -eq 3 ];
do
    echo -e "active connections:$CON, delta $[CON_NEW - CON]";
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

echo -e "connections lasts at $CON for 3s,exit"


