#!/bin/sh
#rotate_log.sh - yet another shell complement of logrotate.

export PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin
COMPRESS="gzip"
COMPRESS_OPTS="-f"
DOT_Z=".gz"
DATUM=`date +%Y%m%d%H%M%S`

prog=`basename $0`
exitcode=0

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

savelog(){
    echo "rotate $filename to $LOG" >> $LOG
}

usage()
{
    echo "Usage: $prog [-n nothing] [-m|--mode copytruncate|move] [-s|--size minsize] [-z count] filename"
    echo "	-n         - show doing nothing exactlly"
    echo "	-m mode    - backup files using copytruncate mode or move"
    echo "	-s size    - minimal size to rotate, files smaller than the value will no br rotated"
    echo "	-z count   - file.n.gz rotate to file.<n+1>.gz while n>=count"
    echo "	             file.n rotate to file.<n+1> while n==count-1"
    echo "	filename   - log file names"
}

while getopts n:m:s:z OPT ; do
    case "OPT" in
        n)  echo "n" ;;
        m)  echo "m" ;;
        s)  echo "s" ;;
        z)  echo "z" ;;
        h)  usage; exit 0 ;;
        *)  usage; exit 1 ;;
    esac
done

#switch the $1 to filename list
shift $(($OPTIND - 1))


# option checking
if [ "$count" -lt 2 ]; then
	echo "$prog: count must be at least 2" 1>&2
	exit 2
fi



while [ $# -gt 0 ]; do

#    some code here

done

exit $exitcode
