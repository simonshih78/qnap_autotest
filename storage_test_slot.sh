#!/bin/sh
# Program:
# This program will help to do dd_testing by stress
# There are two parameter need to input: test count and file size 
# could use ./dd_stress_test &> log.txt to log file.
# History:
# 2015/6/15	SimonShih	First release

second=30
file="./log.txt"
VAR="analysis.log"
try=$1
F_SIZE=$2
erase_flag=$3
thread=1
ionum=1
reportfile=fio_report_eachssd.csv
file=dev.txt
#===========================================================
if [ $# -ne 3 ]; then
    echo "Usage: ./dd_stress_test.sh {test_count} {file_size} {SecureErase}"
    #echo $#
    exit -1
fi

#Create the disk config if file not exist.

if [ ! -f ${file} ]; then
    #count=`cat /etc/enclosure_0.conf | grep pd_sys_name | wc -l`
    cat /etc/enclosure_0.conf | grep pd_sys_name | cut -d '=' -f2 > dev.txt
    echo dev.txt has been created!
fi

#===========================================================
#for line in $ (cat file.txt) do echo "$ line" done
#dd write all of device.

function DiskWriteTest() 
{
    #parameter: /dev/sdx,count,size of test file
	line=$1
	try=$2
	num=$3
    #==================DD write test=====================
    echo "[$(($try + 1)) times] Time DD Write Starting..."
    echo "Writing ${num} MBytes file size to ${line}..."
    time dd if=/dev/zero of=${line} bs=1M count=${num} 
    sleep 2
    echo "Time DD Write done!."
}

function DiskReadTest() 
{
    #parameter: /dev/sdx,count,size of test file
	line=$1
	try=$2
	num=$3
    #==================DD read test=====================
    echo "[$(($try + 1)) times] Time DD Read Starting..."
    echo "Reading ${num} MBytes file size to ${line}..."
    time dd if=${line} of=/dev/null bs=1M count=${num} 
    sleep 2
    echo "Time DD Read done!."
}
debug()
{
    DATE=`date '+%Y-%m-%d-%H-%M'`
    echo $1
    echo ${DATE}:$1 >> ${reportfile}	
}

SleepTime()
{
    second=$1
    echo "===Waiting ${second}s to do next time testing...==="
    sleep ${second}
    echo "===Time's up to do next time testing...==="
}

Erase_EntireSSD()
{
    fio --filename=$1 --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=1M --name=test --size=100% --numjobs=1 --iodepth=1 --rw=write
}

if [ "${erase_flag}" == "YES" ]; then

    #Perfrom SecureErase  on Overall SSD in SYS
    for line in $(cat dev.txt)
    do 
        echo "Erase ${line} now..."
        #do dd test so many times. (depend on times)
        Erase_EntireSSD ${line}
    done
    echo "======== Erase DONE !!! ========"
fi

for line in $(cat dev.txt)
do 
    for ((try=0; try<$1; try++))
    do
        debug "==================[$(($try + 1)) times]====================="
        debug  "testing ${line}..."
	    debug "==================[SR TEST]====================="
        fio --filename=${line} --numjobs=${thread} --iodepth=${ionum} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=1M --rw=read  --name=test --time_based --runtime=180 --size=${F_SIZE} | grep 'bw=' >> ${reportfile}
    done
done
echo "======== FILE STRESS TEST DONE !!! ========"


for line in $(cat dev.txt)
do 
    for ((try=0; try<$1; try++))
    do
        debug "==================[$(($try + 1)) times]====================="
        debug  "testing ${line}..."
	    debug "==================[SW TEST]====================="
        fio --filename=${line} --numjobs=${thread} --iodepth=${ionum} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=1M --rw=write  --name=test --time_based --runtime=180 --size=${F_SIZE} | grep 'bw=' >> ${reportfile}

        echo ""
    done
done
echo "======== FILE STRESS TEST DONE !!! ========"


for line in $(cat dev.txt)
do 
    for ((try=0; try<$1; try++))
    do
        debug "==================[$(($try + 1)) times]====================="
        debug  "testing ${line}..."
	    debug "==================[RR TEST]====================="
        fio --filename=${line} --numjobs=${thread} --iodepth=${ionum} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=4k --rw=randread  --name=test --time_based --runtime=180 --size=${F_SIZE} | grep 'bw=' >> ${reportfile}
        echo ""
    done
done
echo "======== FILE STRESS TEST DONE !!! ========"

for line in $(cat dev.txt)
do 
    for ((try=0; try<$1; try++))
    do
        debug "==================[$(($try + 1)) times]====================="
        debug  "testing ${line}..."
	    debug "==================[RW TEST]====================="
        fio --filename=${line} --numjobs=${thread} --iodepth=${ionum} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=4k --rw=randwrite  --name=test --time_based --runtime=180 --size=${F_SIZE} | grep 'bw=' >> ${reportfile}
        echo ""
    done
done
echo "======== FILE STRESS TEST DONE !!! ========"


exit 0
