#!/bin/bash

#=================================
#Variable Area
#=================================

bs=1M
size=100G
runtime=3m
numjobs=1
iodepth=64
direct=1
filename=$1
test_items=directio
#test_items=bufferio
#test_items=all
#filename=/dev/xxx

#=================================
#FIO Function Area
#include: random or sequecient read and write.
#=================================
#direct io first.
DO_FIO_SR_DirectIO()
{
    echo "seq. read -> directio"
    fio --filename=${filename} --numjobs=${numjobs} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=1M \
    --rw=read --iodepth=${iodepth} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}

DO_FIO_SW_DirectIO()
{
    echo "seq. write -> directio"
    fio --filename=${filename} --numjobs=${numjobs} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=1M \
    --rw=write --iodepth=${iodepth} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}
DO_FIO_RR_DirectIO()
{
    echo "rand. read -> directio"
    fio --filename=${filename} --numjobs=${iodepth} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=4k \
    --rw=randread --iodepth=${numjobs} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}

DO_FIO_RW_DirectIO()
{
    echo "rand. write -> directio"
    fio --filename=${filename} --numjobs=${numjobs} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=1 --bs=4k \
    --rw=randwrite --iodepth=${iodepth} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}
#bufferIO
DO_FIO_SR_BufferIO()
{
    echo "seq. read -> bufferio"
    fio --filename=${filename} --numjobs=${numjobs} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=0 --bs=1M \
    --rw=read --iodepth=${iodepth} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}

DO_FIO_SW_BufferIO()
{
    echo "seq. write -> bufferio"
    fio --filename=${filename} --numjobs=${numjobs} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=0 --bs=1M \
    --rw=write --iodepth=${iodepth} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}
DO_FIO_RR_BufferIO()
{
    echo "rand. read -> bufferio"
    fio --filename=${filename} --numjobs=${iodepth} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=0 --bs=4k \
    --rw=randread --iodepth=${numjobs} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}

DO_FIO_RW_BufferIO()
{
    echo "rand. write -> bufferio"
    fio --filename=${filename} --numjobs=${numjobs} --ioengine=libaio --gtod_reduce=1 --group_reporting --direct=0 --bs=4k \
    --rw=randwrite --iodepth=${iodepth} --name=test --time_based --runtime=${runtime} --size=${size} | grep 'bw=' | cut -d ',' -f2,3 >> fio_report.csv
}

Do_Erase()
{
    ./hdparm --user-master u --security-set-pass Eins /dev/${dev}
    ./hdparm --user-master u --security-erase Eins /dev/${dev}
}
Do_Erase_all()
{
    for dev in sda sdb sdc sdd sde sdf
    do
        do_erase
    done
}

Build_MD_Layer()
{
    echo y | mdadm --create --verbose /dev/md0 --level=0 --raid-devices=18 /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds
}

Remove_MD_Layer()
{
    mdadm --stop /dev/md0
}

#=================================
#Main() Area
#=================================
#DO_FIO_SW
echo "================================="
echo "1. Do Seq Read/Write DirectIO"
echo "2. Do Rand Read/Write DirectIO"
echo "3. Do Seq Read/Write BufferIO"
echo "4. Do Rand Read/Write  BufferIO"
echo "================================="
for (( i=1; i<=3; i=i+1 ))
do
    echo ======== ${i} times fio overall test starting... ========
	if [ "${test_items}" == "directio" ] || [ "${test_items}" == "all" ]; then
        #DirectIO
		echo "SR_DirectIO" >> fio_report.csv
		DO_FIO_SR_DirectIO
		echo "SW_DirectIO" >> fio_report.csv
		DO_FIO_SW_DirectIO
		echo "RR_DirectIO" >> fio_report.csv
		DO_FIO_RR_DirectIO
		echo "RW_DirectIO" >> fio_report.csv
		DO_FIO_RW_DirectIO
	elif [ "${test_items}" == "bufferio" ] || [ "${test_items}" == "all" ]; then
        #bufferIO
		echo "SR_BufferIO" >> fio_report.csv
                DO_FIO_SR_BufferIO
		echo "SW_BufferIO" >> fio_report.csv
                DO_FIO_SW_BufferIO
		echo "RR_BufferIO" >> fio_report.csv
                DO_FIO_RR_BufferIO
		echo "RW_BufferIO" >> fio_report.csv
                DO_FIO_RW_BufferIO
	fi
    echo ======== ${i} times fio overall test done. ========
	echo " " >> fio_report.csv
done
#echo "read:" > read.txt;cat fio_report.csv | grep -i 'read' | grep -i 'bw=' | awk '{print $4}'  | cut -d '=' -f2,3 | cut -d 'K' -f1 | awk '{print $0" MB/s"}' >> read.txt;
#cat fio_report.csv | grep -i 'read' | grep -i 'bw=' | awk '{print $5}'  | cut -d '=' -f2,3 | cut -d 'K' -f1 | awk '{print $0" IOPS"}' >> read.txt
#echo "write:" > write.txt;cat fio_report.csv | grep -i 'write' | grep -i 'bw=' | awk '{print $3}'  | cut -d '=' -f2,3 | cut -d 'K' -f1 | awk '{print $0" MB/s"}' >> write.txt
#cat fio_report.csv | grep -i 'write' | grep -i 'bw=' | awk '{print $4}'  | cut -d '=' -f2,3 | cut -d 'K' -f1 | awk '{print $0" IOPS"}' >> write.txt
#echo "There were three log files generated -> fio_report.csv, read.txt, and write.txt."
