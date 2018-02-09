#!/bin/bash
#===========================================================
# Program:
# This program will help to do raid config testing by stress
# There are four parameter need to input,please refer to Usage 
# Usage: ./mdadm_stress_test.sh [TEST SIZE] [DEVICE AMOUNT] [RAID TYPE]
# Could use ./mdadm_stress_test.sh 3 ${sleep_time}240 2 0 &> to save logfile 
# History:
# 2015/6/15	SimonShih	First release
# 2017/4/5	SimonShih	change tool from dd to fio and call the another shell for md_stress
#===========================================================
md_dev=/dev/md2
sleep_time=10
dev_num=$2
raid_type=$3
#===========================================================
#Determine the input parameter.
#===========================================================
if [ $# -ne 3 ]; then
    echo "Usage: ./mdadm_stress_test.sh [TEST SIZE] [DEVICE AMOUNT] [RAID TYPE]"
    #echo $#
    exit -1
fi

if [ -f dev.txt ]; then
    echo "dev.txt has created! the testing ready to perform..."
    cat /etc/enclosure_*.conf | grep model
    sleep ${sleep_time}
else
    cat /etc/enclosure_*.conf | grep pd_sys_name | cut -d '=' -f2 > dev.txt
    echo "device list has done and save to dev.txt"
    cat /etc/enclosure_*.conf | grep model
    cat dev.txt
    sleep ${sleep_time}
    echo dev.txt has been created!
fi
#===========================================================
#Generate the RAID configuration. ($2 is how many device need to config to RAID configuration.)
#===========================================================
ARRAY=$(cat dev.txt | sed ''$((${dev_num}+1))',$'d)
mdadm --zero-superblock ${ARRAY[*]}
mdadm --create ${md_dev} --level=${raid_type} --raid-devices=${dev_num} ${ARRAY[*]}
sata=`cat /sys/class/ata_link/link*/sata_spd`
echo "LINK SPEED: ${sata}"
flag=$(cat /proc/mdstat | grep none)
if [ -z "${flag}" ]; then
    echo "The RAID generated failed!"
    exit -1
fi    
#determine if sync progress not ready.
cat /proc/mdstat | grep "recovery" > /dev/null
ret=$?
if [ "${ret}" -eq 0 ]; then
	while [ "${ret}" -eq 0 ]
	do
		sleep 60
		cat /proc/mdstat | grep "recovery" > /dev/null
		ret=$?
		sync_progress=$(cat /proc/mdstat | grep % | awk '{print $4}')
		#The sync dose not done
		echo "RAID Sync:${sync_progress}"
	done
		#The sync done and the dd testing will be starting...
	echo "RAID Generated and Sync done."
fi
echo ""
echo "===== List RAID Info: ====="
mdadm --detail ${md_dev}
sleep ${sleep_time}
echo "======================================================"
#echo "Some Devices config to RAID configuration."
#ARRAY1=$(mdadm --detail /dev/md0 | grep -A${sleep_time} Number | awk '{print $7}')
echo ""

#===========================================================
#Perform FIO Stree to MD Level
#===========================================================
echo "[$(($try + 1))] Perform FIO Stree to MD Level..." 
./mdlevel_stress_test.sh ${md_dev}
echo "***ALL TEST SUITE DONE.***" 
done
#===========================================================
#STOP RAID Service.
#===========================================================
mdadm -S ${md_dev}
echo "RAID configuration stress testing done and removed the RAID configuration." 
