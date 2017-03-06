#!/bin/sh
#rotate_log.sh - yet another shell complement of logrotate.

export PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin

SAVE_DIR=/tmp/

prog=`basename $0`

usage()
{
    echo "Usage: $prog [-n nothing] [-m|--mode truncate|move] [-s|--size minsize] [-z count] filename"
    echo "  -n         - show doing nothing exactlly"
    echo "  -m mode    - backup files using copytruncate mode or move"
    echo "  -s size    - minimal size to rotate, files smaller than the value will no br rotated"
    echo "             - the size can end with g/m/k, such as '-s 10k' or '-s 10m' "
    echo "  -z count   - file.n.gz rotate to file.<n+1>.gz while n>=count"
    echo "               file.n rotate to file.<n+1> while n==count-1"
    echo "  filename   - log file names"
}

calc()
{
    awk "BEGIN{print $*}";
}

check_arg()
{
    if echo $1 | egrep -q '^[0-9]+$'; then :
    else echo -e "\nThe input $1 is not a valid number!\n" && exit 1;
    fi
}

check_size()
{
    file=file.txt
    minimumsize=90000
    actualsize=$(wc -c <"$file")
    if [ $actualsize -ge $minimumsize ]; then
        echo size is over $minimumsize bytes
    else
        echo size is under $minimumsize bytes
    fi
}

filesize()
{
    # filename=media.log
    filesize=`wc -c " $filename" | awk '{print $1}'`
    maxsize=$((1024*10))
    if [ $filesize -gt $maxsize ]; then
    echo "$filesize > $maxsize"
        mv media.log media"`date +%Y-%m-%d_%H:%M:%S`".log
    else
    echo "$filesize < $maxsize"
    fi
}

savelog()
{
    echo "rotate $filename to $LOG" >> $LOG
}

check()
{
    #check the mode
    echo "checking mode..."
    if [ $mode = move ]; then
        echo -e "\nmode is move\n"
    elif [ $mode = truncate ]; then
        echo -e "\nmode is truncate\n"
    else
        echo -e "\ninvalid mode $mode\n"; exit 1;
    fi

    #check the minimal size is a number
    echo "checking minimal size..."

    case "${minsize: -1}" in
        g)  ((unit=1024*1024*1024)) ;;
        m)  ((unit=1024*1024)) ;;
        k)  ((unit=1024)) ;;
        *)  echo "invalid size"; exit 1;;
    esac

    #size=`awk '{flag=match($0,"[gmk]");print flag;print substr($0,1,flag-1)}' <<< $size`

    if echo ${minsize%%[gmk]} | egrep -q '^[0-9]+$'; then
        echo -e "\nthe minimal file to rotate is $minsize\n"
    else
        echo -e "\nThe size $minsize is not a valid number!\n" ; exit 1;
    fi

    #check the count to gzip is a number
    echo "checking the count to gzip..."
    if echo $count | egrep -q '^[0-9]+$'; then
        echo -e "\nthe count to gzip is $count\n"
    else
        echo -e "\nThe count $count is not a valid number!\n" ; exit 1;
    fi
}

show()
{
    #show what to do
    echo "file $[$filenumber - $#] is $filename"

}

execute()
{
    #some code here
    if [ $mode = move ]; then
        :
    else
        :;
    fi
}

while getopts ":nm:s:z:h" optname
do
    case "$optname" in
        "n")    echo $OPTARG; echo "Option $optname is specified" ;;
        "m")    mode=$OPTARG ;;
        "s")    minsize=$OPTARG ;;
        "z")    count=$OPTARG ;;
        "h")    usage; exit 0 ;;
        "?")    echo "Unknown option $OPTARG"; usage; exit 1 ;;
#debug info        ":")    echo "No argument value for option $OPTARG" ;;
        *)      echo "Unknown error while processing options"; usage; exit 1 ;;
    esac
    echo "OPTIND is now $OPTIND"
done

#switch the $1 to filename list
shift $(($OPTIND - 1))
#echo $1

#main options check
check

echo $#
#main loop
filenumber=$#
while [ $# -gt 0 ];
do
    filename=$1
    shift
    echo "file $[$filenumber - $#] is $filename"
    execute
#    some code here
done

# exit $exitcode
