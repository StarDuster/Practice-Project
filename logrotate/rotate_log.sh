#!/bin/sh
#rotate_log.sh - yet another shell script complement of logrotate.

export LANG=en_US
export LC_ALL=en_US.UTF-8
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:$PATH

logdir=/logrotate

#set default value
program=`basename $0`
nothing=0
mode=move
count=5

usage()
{
    echo "Usage: $program [-n nothing] [-m|--mode truncate|move] [-s|--size minsize] [-z count] filename"
    echo "  -n         - show the plan but doing nothing exactlly"
    echo "  -m mode    - backup files using copytruncate mode or move"
    echo "  -s size    - minimal size to rotate, files smaller than the value will not be rotated"
    echo "             - the size can end with g/m/k, such as '-s 10k' or '-s 10m' "
    echo "  -z count   - file.n.gz rotate to file.<n+1>.gz while n>=count, default is 5"
    echo "               file.n rotate to file.<n+1> while n==count-1"
    echo "  filename   - log file names"
}

calc()
{
    awk "BEGIN{print $*}";
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

checkoption()
{
    #check option -m
    echo "checking mode..."
    if [ $mode = move ]; then
        echo -e "\nmode is move\n"
    elif [ $mode = truncate ]; then
        echo -e "\nmode is truncate\n"
    else
        echo -e "\nInvalid mode $mode\n" 1>&2 ; exit 1;
    fi

    #check option -s
    echo "checking minimal size..."

    case "${minsize: -1}" in
        [Gg])  ((unit=1024*1024*1024)) ;;
        [Mm])  ((unit=1024*1024)) ;;
        [Kk])  ((unit=1024)) ;;
        *)  echo "Invalid size unit, use g/m/k" 1>&2 ; exit 1;;
    esac

    #another choice, use awk for better portablity
    #size=`awk '{flag=match($0,"[gmk]");print flag;print substr($0,1,flag-1)}' <<< $size`

    if echo ${minsize%%?} | egrep -q '^[0-9]+$'; then
        echo -e "\nThe minimal file to rotate is $minsize\n"; sizenumber=${minsize%%?}
    else
        echo -e "\nThe size $minsize is not a valid number!\n" 1>&2 ; exit 1;
    fi

    #check option -z
    echo "checking the count to gzip..."
    if echo $count | egrep -q '^[0-9]+$'; then
        echo -e "\nThe count to gzip is $count\n"
    else
        echo -e "\nThe count $count is not a valid number!\n" 1>&2 ; exit 1;
    fi

    #check savedir
    savedir=`dirname "$filename"`$logdir
    if [ -z "$savedir" ]; then
        savedir=.
    fi
    if [ ! -d "$savedir" ]; then
        mkdir -p "$savedir"
        if [ "$?" -ne 0 ]; then
            echo "could not mkdir $savedir" 1>&2;
        fi
        chmod 0755 "$savedir"
    fi
    if [ ! -w "$savedir" ]; then
        echo "directory $savedir is not writable, save to /tmp"; mkdir -p /tmp$logdir/; savedir="/tmp$logdir";
    fi

    echo -e "all options checked\n"
}

checkfile()
{
    #check if the files in list exist
    if [ -e "$filename" ] && [ -f "$filename" ]; then
        echo "file $filename check pass"
    else
        echo -e "file $filename not exist or not regular file, jump over\n"; continue;
    fi
}

checksize()
{
    #check if the files in list smaller than the minsize to rotate
    filesize=`wc -c<"$filename" | awk '{print $1}'`
    if [ $filesize -lt $((sizenumber*unit)) ]; then
        echo -e "$filename is smaller than minsize, jump over\n"; continue;
    fi
}

show()
{
    #show what to do
    newname=`basename "$filename"`
    newname="$savedir/$newname"
    echo -e "File No.$[$filenumber - $1] is $filename"
    echo -e "Saving to $newname\n"

}

execute()
{
    #execute here
    if [ $mode = move ]; then
        echo "call function execute for $filename"
    else
        :;
    fi
}

while getopts ":nm:s:z:h" optname
do
    case "$optname" in
        "n")    nothing=1; echo -e "Option $optname is specified, the $program will actually doing nothing\n" ;;
        "m")    mode=$OPTARG ;;
        "s")    minsize=$OPTARG ;;
        "z")    count=$OPTARG ;;
        "h")    usage; exit 0 ;;
        "?")    echo "Unknown option $OPTARG"; usage; exit 1 ;;
        ":")    echo "No argument value for option $OPTARG" ;;
        *)      echo "Unknown error while processing options"; usage; exit 1 ;;
    esac
done

#switch the $1 to filename list
shift $(($OPTIND - 1))

#main options check
checkoption

#main loop, until the file list was enpty
filenumber=$#
while [ $# -gt 0 ];
do
    filename=$1
    shift
 
    checkfile $1
    checksize $1

    #be careful about the enviroment of argument when calling functions
    show $#

    if [ $nothing -ne 1 ]; then
        execute
    fi

done

# exit $exitcode
