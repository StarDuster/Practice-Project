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
    echo "               file.n rotate to file.<n+1> while n==count-1, default is 5"
    echo "  filename   - log file names, e.g. '/path/to/file.log' or 'file.log' for current dir"
    echo "             - please DO enter the full filename partern with no wildcard character "
    echo "             - e.g. 'rsync.d.log' can NOT be replaced by 'rsync.d.log.' or 'rsync*' "
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
    echo "checking the count to rotate..."
    if echo $count | egrep -q '^[0-9]+$'; then
        echo -e "\nThe count to rotate is $count\n"
    else
        echo -e "\nThe count $count is not a valid number!\n" 1>&2 ; exit 1;
    fi

    echo -e "all options checked\n"
}

checkdir()
{
    #check savedir
    savedir=`dirname "$filelist"`$logdir
    if [ -z "$savedir" ]; then
        savedir=/tmp$logdir
    fi
    if [ ! -d "$savedir" ]; then
        mkdir -p "$savedir"
        if [ "$?" -ne 0 ]; then
            echo "could not mkdir $savedir" 1>&2;
        else
            chmod 0755 "$savedir"
        fi
    fi
    if [ ! -w "$savedir" ]; then
        echo "directory $savedir is not writable, save to /tmp"; mkdir -p /tmp$logdir/; savedir="/tmp$logdir";
    fi
    echo -e "savedir is $savedir\n"

}

checkfile()
{
    #check if the files in list exist
    if [ -e "$filename" ] && [ -f "$filename" ]; then
        echo "file $filename check pass"
    else
        echo -e "file $filename not exist or not regular file, jump over\n"; ((filenumber=filenumber-1)); continue;
    fi
}

checksize()
{
    #check if the files in list smaller than the minsize to rotate
    filesize=`wc -c<"$filename" | awk '{print $1}'`
    if [ $filesize -lt $((sizenumber*unit)) ]; then
        echo -e "$filename is smaller than minsize, jump over\n"; ((filenumber=filenumber-1)); continue;
    fi
}

show()
{
    #show what to do
    newname=`basename "$1"`
    newname="$savedir/$newname"
    echo -e "File No.$[$filetotal - $filenumber+1] is $1"
    if [ $filenumber -gt $count ]; then
        echo -e "Saving $1 to $prefix.$((filenumber)).gz\n"
    else
        echo -e "Saving $1 to $prefix.$((filenumber))\n"
    fi
}

execute()
{
    #execute here
    if [ $mode = move ]; then
        echo -e "call function execute for $1 to execute\n"
    else
        :;
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

#count the dot in filename to ensure sort success
#be careful about the enviroment of argument when calling subshells
dotnumber=$(echo $1| grep -o '\.'|wc -l|awk '{print $1}')

#get the file list and the number of files
filelist=(`ls $1*|sort -t '.' -k$((dotnumber+2)) -n`)
filetotal=$(ls $1*|wc -l|awk '{print $1}')
gztotal=$(ls $1.*.gz|wc -l|awk '{print $1}')

echo -e "total $filetotal files, $gztotal gzipped\n"

#get the prefix of the file
prefix=`basename $1`

#main options check
checkoption
checkdir

filenumber=$filetotal

#main loop, until the file list was enpty
while [ $filenumber -gt 0 ];
do
    filename=${filelist[$filenumber-1]}

    #check file, shift filenumber in check function if failed
    checkfile $filename
    checksize $filename

    #infix is the number inside the filename, the suffix is .gz or none
    infix=$(echo $filename|cut -d '.' -f $((dotnumber+2)))

    show $filename

    if [ $nothing -ne 1 ]; then
        execute $filename
    fi

    ((filenumber=filenumber-1))
    #count down the filenumber when execute success

done

# exit $exitcode
