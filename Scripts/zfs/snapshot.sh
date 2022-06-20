#!/bin/bash
#configure these
POOLNAME="zroot"
PREFIX="snappy"
MAX_NUMBER_SNAPSHOTS=10
ZFS="sudo /sbin/zfs"
#in seconds
TIME_BETWEEN_SNAPSHOTS=500

#global variable
rootname=""
diff=0

time_last_snapshot(){
    NOW=$(/bin/date +%s)
    # get all snapshots of zfs filesystem and search for newest snapshot
    CREATIONDATE=$($ZFS get creation -Hpr -t snapshot $FSNAME | grep $PREFIX | /bin/awk 'BEGIN {max = 0} {if ($3>max) max=$3} END {print max}')

    diff=$((NOW-CREATIONDATE))

    echo $diff
}

get_rootname() {
    filesystem=""
    mounted=""
    while read -r line ; do
        read -a strarr <<< "$line"
        filesystem="${strarr[0]}"
        mounted="${strarr[5]}"
        
        #echo "filesystem $filesystem"
        #echo "mounted $mounted"
        if [ "$mounted" == "/" ]; then
            rootname=$filesystem
        fi
    done < <(df)

#     echo $rootname
}

create () {
    time=$(date +%Y_M-%m_D-%d_T-%H_%M_%S)
    $ZFS snapshot -r $rootname@$PREFIX-$time
}

purge() {
    while read -r dataset ; do
        if [ "$($ZFS list -t snapshot -o name -S creation | grep $dataset@$PREFIX)" != "" ]; then
#             echo "FOUND"
#             echo $dataset
            removalDatasets=$($ZFS list -t snapshot -o name -S creation | grep $dataset@$PREFIX | tail -n +$MAX_NUMBER_SNAPSHOTS )
            if [ "$removalDatasets" != "" ]; then
                echo $removalDatasets | xargs -n 1 zfs destroy
            fi
#         echo ""
        fi
    done < <($ZFS list -o name)
}

time_last_snapshot
get_rootname
if [ $diff -gt $TIME_BETWEEN_SNAPSHOTS ]; then
    create
fi

purge
