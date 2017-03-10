#!/bin/bash
#rotate_log.sh - yet another shell script complement of logrotate.

export LANG=en_US
export LC_ALL=en_US.UTF-8
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:$PATH

#set default value
program=`basename $0`
nothing=0
mode=move
minsize=10k
count=5

usage()
{
    echo "Usage: $program [-n nothing] [-m truncate|move] [-s minsize] [-z count] filename"
    echo "  -n         - show the plan but doing nothing exactlly"
    echo "  -m mode    - backup files using copy-truncate mode or move-newfile mode"
    echo "             - default is move, DO NOT use truncate mode on non-linux system"
    echo "  -s size    - minimal size to rotate, files smaller than the value will not be rotated"
    echo "             - the size can end with g/m/k, e.g. '-s 10K' or '-s 10m', default is 10K "
    echo "  -z count   - file.n.gz rotate to file.<n+1>.gz while n>=count"
    echo "               file.n rotate to file.<n+1> while n<count, default is 5"
    echo "  filename   - log file names, e.g. '/path/to/file.log' or 'file.log' for current dir"
    echo "             - please DO enter the full filename partern with no wildcard character "
    echo "             - e.g. 'rsync.d.log' can NOT be replaced by 'rsync.d.log.' or 'rsync*' "
}

check_option()
{
    #check option -m
    echo "checking mode..."
    if [ $mode = move ]; then
        echo -e "\nmode is move\n"
    elif [ $mode = truncate ]; then
        if uname -a | grep -iq "linux"; then
            echo -e "\nmode is truncate\n"
        else
            echo -e "\ncommand truncate only available on linux, exit" 1>&2 ; exit 1
        fi
    else
        echo -e "\nInvalid mode $mode\n" 1>&2 ; exit 1
    fi

    #check option -s
    echo "checking minimal size..."

    if echo ${minsize%%?} | egrep -q '^[0-9]+$'; then
        echo -e "\nThe minimal file to rotate is $minsize\n"; sizenumber=${minsize%%?}
    else
        echo -e "\nThe size $minsize is not a valid number!\n" 1>&2 ; exit 1
    fi

    #parameter expansion "${minsize: -1}" is simpler, use parttern match for compatible
    case "${minsize##*[0-9]}" in
        [Gg])  unit=$((1024*1024*1024)) ;;
        [Mm])  unit=$((1024*1024)) ;;
        [Kk])  unit=$((1024)) ;;
        *)  echo "Invalid size unit, use g/m/k" 1>&2 ; exit 1;;
    esac

    #check option -z
    echo "checking the count to gzip..."
    if echo $count | egrep -q '^[0-9]+$' && [ $count -gt 0 ] ; then
        echo -e "\nThe count to gzip is $count\n"
    else
        echo -e "\nThe count $count is not a valid number!\n" 1>&2 ; exit 1
    fi

    echo -e "all options checked\n"
}


check_file()
{
    #check if the files in list exist
    if [ -e "$filename" ] && [ -f "$filename" ]; then
        echo -e "file $filename check pass\n"
    else
        echo -e "file $filename not exist or not regular file, jump over\n"; exit 1
    fi

    #check if the files in list smaller than the minsize to rotate
    filesize=`wc -c<"$filename" | awk '{print $1}'`
    if [ $filesize -lt $((sizenumber*unit)) ]; then
        echo -e "$filename is smaller than minsize, jump over\n"; exit 1
    fi
}

get_total_file()
{
    #get the file list and the number of files,
    #use awk to avoid space in front of the wc result
    filetotal=$(ls $filename* 2> /dev/null|wc -l|awk '{print $1}')
    gztotal=$(ls $filename.*.gz 2> /dev/null|wc -l|awk '{print $1}')
    ungztotal=$((filetotal-$gztotal))

    echo -e "\ntotal $filetotal files, $gztotal gzipped, $ungztotal not gzipped\n"

}

#the execute_* functions are the functions actually operate the files
#the process_* functions just show what to do, check the -n flag then call execute_* functions

execute_rotate()
{
    if [ $mode = move ]; then
        mv $prefix$postfix $prefix$newpostfix; touch $prefix$postfix
    else
        cp $prefix$postfix $prefix$newpostfix; truncate -s 0 $prefix$postfix
    fi
}

process_rotate()
{
    #first treat origin file, then gz file
    if [ -z $filenumber ]; then
        postfix="$filenumber";
        newpostfix=".1"
    elif [ $filenumber -gt $((ungztotal-1)) ]; then
        postfix=".$filenumber.gz";
        newpostfix=".$((filenumber+1)).gz"
    elif [ $filenumber -gt 0 ]; then
        postfix=".$filenumber";
        newpostfix=".$((filenumber+1))"
    else
        echo -e "\nwrong number"; exit 1
    fi

    echo -e "processing $prefix$postfix, rotate to $prefix$newpostfix"
    if [ $nothing -eq 1 ]; then
        :
    else
        execute_rotate
    fi
}

execute_gzip()
{
    gzip -f $prefix$postfix
}

process_gzip()
{
    postfix=".$filenumber"
    newpostfix="$postfix.gz"
    echo -e "gzip $prefix$postfix, save to $prefix$newpostfix"
    if [ $nothing -eq 1 ]; then
        :
    else
        execute_gzip
    fi
}
#main entrance of the script
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
check_option

#check file existence and size, will not go into main loop if failed
filename=$1
prefix=$1
check_file $filename

#main loop, to rotate the files
get_total_file
filenumber=$((filetotal-1))

#main loop, to rotate the files
while [ $filenumber -gt 0 ];
do
    process_rotate $filenumber
    filenumber=$((filenumber-1))
    #count down the filenumber when execute success
done

#process the origin file without number
filenumber=""
process_rotate $filenumber

#a rotate loop make uncopressed file number+1
ungztotal=$((ungztotal+1))

#second loop to gzip the files
filenumber=$((ungztotal-1))

until [ $filenumber -lt $count ];
do
    process_gzip $filenumber
    filenumber=$((filenumber-1))
done

get_total_file

exit 0