#!/bin/bash

#Author: simonshih@qnap.com
#Date:20170331
#Purpose:
#To measure the network bandwidth by iperf2/iperf3 and vaildate the MTU of driver function workable
#
# v1.0 - init iperf feature
# v1.1 - add dual port test case
# v1.2 - add fix some issue, don't config dual port settings if one port only.
# v1.3 - add ping validation function.
# v1.4 - add set link speed function for 100Mbps - 10Gbps validation.

#Usage:
#./net_stress.sh [s/c] [all/single_port/dual_port] [IP1] [IP2] [ethx] [ethx] 
#./net_stress.sh c all 10.1.1.1 10.1.1.2 eth1 eth2
#s is server side and c is client.
#IP means target_ip
#ethx is which one interface that would like to test.

#=================================
#Variable Area
#=================================
#usage: ./net_stress.sh [s/c] [IP]
mode=$1
op=$2
target_ip1=$3
target_ip2=$4
intface1=$5
intface2=$6
speed=(10000 1000 100)
#speed=(1000 100)
mtu=(1500 9000)
#mtu=(9000)
thread=(1 4)
iperf=iperf3
#iperf=./iperf
#=================================
#function area
#=================================
function ping_validation()
{
    ip_addr=$1
    ping -c 5 ${ip_addr} > /dev/null
    ret=$?
    if [ ${ret} -eq 1 ]; then
        #could not ping target
        echo -1
    else
        #ping target success
        echo 0
    fi
}
function iperf_test()
{
    time=60
    #time=3600
    inv=1
    mode=$1
    op=$2
    target_ip1=$3
    target_ip2=$4
    intface1=$5
    intface2=$6
    w_size=320K
    ret=99
    echo "================================="
    echo "============  VAR ==============="
    echo "================================="
    echo "Time=${time}"
    echo "Target1=${target_ip1}"
    echo "Target2=${target_ip2}"
    echo "Mode=${op}"
    echo "Thread=${thread}"
    echo "Window Size=${w_size}"
    echo "================================="
    #IFS=:
    #thread=($thread)
    #IFS=" "
    #echo "thread=${thread[@]}"
    echo "================================="
    if [ "${mode}" == "c" ];then
	    #echo "here is client side now."
        if [ "${op}" == "all" ] || [ "${op}" == "single_port" ];then
            for P in "${thread[@]}"
            do
			    debug " "
                debug "iperf_test(): do iperf ${P} thread  via ${target_ip1}, ${intface1}"
                for (( i=1; i<=3; i=i+1 ))
                do 
                    #perform single port testing.
                    if [ "${P}" == "1" ];then
                        echo "Checking Target now..."
                        ret=$(ping_validation ${target_ip1})
                        if [ ${ret} -eq 0 ]; then
                            debug "target is alive."
    			            debug "${i} times : ${iperf} -c ${target_ip1} -t ${time} -f M -w 320K -P ${P} "
		    	            ${iperf} -c ${target_ip1} -t ${time} -f M -w 320K -P ${P} |grep -i -E "0.0.*${time}.0" >>iperf.log &
                        else
                            debug "target could not access, please check ip first."
                            debug "dead: in single mode, ${P} thread, ip: ${target_ip1}, ${target_ip2}"
                            get_nic_info ${intface1}
                            get_nic_info ${intface2}
                            exit -1
                        fi
                    else
                        echo "Checking Target now..."
                        ret=$(ping_validation ${target_ip1})
                        if [ ${ret} -eq 0 ]; then
                            debug "target is alive."
                            debug "${i} times : ${iperf} -c ${target_ip1} -t ${time} -f M -w 320K -P ${P} "
                            ${iperf} -c  ${target_ip1} -t ${time} -f M -w 320K -P ${P} |grep -i -E "[SUM].*0.0.*${time}.0" >>iperf.log &
                    
                        else
                            debug "target could not access, please check ip first."
                            debug "dead: in single mode, ${P} thread, ip: ${target_ip1}, ${target_ip2}"
                            get_nic_info ${intface1}
                            get_nic_info ${intface2}
                            exit -1
                        fi
                    fi
                    wait
                    sleep 5
        #If IP2 is not empty please also test IP2
         if [ "${target_ip2}" != "0" ]; then
            debug "iperf_test(): testing iperf via ip2:${target_ip2}"
                if [ "${P}" == "1" ];then
                    echo "Checking Target now..."
                    ret=$(ping_validation ${target_ip2})
                    if [ ${ret} -eq 0 ]; then
                        debug "target is alive."
             	        debug "${i} times : ${iperf} -c ${target_ip2} -t ${time} -f M -w 320K -P ${P} "
            	        ${iperf} -c ${target_ip2} -t ${time} -f M -w 320K -P ${P} |grep -i -E "0.0.*${time}.0" >>iperf.log &
                    else
                        debug "target could not access, please check ip first."
                        debug "dead: in single mode, ${P} thread, ip: ${target_ip1}, ${target_ip2}"
                        get_nic_info ${intface1}
                        get_nic_info ${intface2}
                        exit -1
                fi
                else
                    echo "Checking Target now..."
                    ret=$(ping_validation ${target_ip2})
                    if [ ${ret} -eq 0 ]; then
                        debug "target is alive."
                        debug "${i} times : ${iperf} -c ${target_ip2} -t ${time} -f M -w 320K -P ${P} "
                        ${iperf} -c ${target_ip2} -t ${time} -f M -w 320K -P ${P} |grep -i -E "[SUM].*0.0.*${time}.0" >>iperf.log &
                    else
                        debug "target could not access, please check ip first."
                        debug "dead: in single mode, ${P} thread, ip: ${target_ip1}, ${target_ip2}"
                        get_nic_info ${intface1}
                        get_nic_info ${intface2}
                        exit -1
                    fi
                fi
         wait
         sleep 5        
         fi
         done
    done
    fi

       if [ "${op}" == "all" ] || [ "${op}" == "dual_port" ];then
           debug "iperf_test(): testing dual port now."
           for P in "${thread[@]}"
               do
       	           debug "do iperf ${P} thread."
       	           for (( i=1; i<=3; i=i+1 ))
                   do
                       if [ "${P}" == "1" ]; then
                           debug "dual mode and 1 thread."
        		           debug "${i} times : ${iperf} -c ${target_ip1} -t ${time} -f M -w 320K -P ${P} "
       	                   ${iperf} -c ${target_ip1} -t ${time} -f M -w 320K -P ${P} |grep -i -E "0.0.*${time}.0" >> iperf.log & ${iperf} -c ${target_ip2} -t ${time} -f M -w 320K -P ${P} |grep -i -E "0.0.*${time}.0" >> iperf.log
           		       else
       			           debug "${i} times : ${iperf} -c ${target_ip1} -t ${time} -f M -w 320K -P ${P} "
       			           ${iperf} -c ${target_ip1} -t ${time} -f M -w 320K -P ${P} |grep -i -E "[SUM].*0.0.*${time}.0" >>iperf.log & ${iperf} -c ${target_ip2} -t ${time} -f M -w 320K -P ${P} |grep -i -E "[SUM].*0.0.*${time}.0" >>iperf.log
       		           fi
       		           wait
       	               sleep 2
       		       done
       	       done
       fi
    else
        echo "Server Side."
        ${iperf} -s -f M
    fi
}

function get_nic_info()
{
    eth=$1
    debug "get_nic_info: ${eth}"
    mtu_tmp=`ifconfig ${eth} |  grep -i 'mtu'|cut -d ':' -f 2 | cut -d " " -f 1`
    tso=`ethtool -k ${eth} | grep -i 'tcp-segmentation-offload'| cut -d ':' -f 2`
    ip_addr=`ifconfig ${eth} | grep -i inet | cut -d ':' -f2 | cut -d ' ' -f1`
    echo "IP:${ip_addr},INTERFACE:${eth}."
    if [ "${mtu}" == "${mtu_tmp}" ]; then
        debug "MTU Setting Status: Success."
        debug "MTU:${mtu_tmp},TSO:${tso}"
    else 
        debug "MTU Setting failed."
        echo "MTU:${mtu},${mtu_tmp}"
        exit -1
    fi
}

function debug()
{
    echo $1
    echo $1 >> iperf.log
}
function mtu_test()
{
    t=60
    mode=$1
    op=$2
    target_ip1=$3
    target_ip2=$4
    intface1=$5
    intface2=$6
    if [ "${target_ip1}" != "0" ] && [ "${target_ip2}" ==  "0" ]; then
        debug "mtu_test():The IP2 is empty"
    	for i in "${mtu[@]}"
    	do 
    	    debug "Setting MTU to $i"
            set_mtu ${intface1} $i
    	    #ifconfig ${intface1} mtu $i
    	    #sleep 3
    	    debug "Set configurations done and Get info MTU of is $i"
    	    debug "*** START TO PERFORM IPERF TESTING ***"
    	    sleep 1
    	    iperf_test ${mode} ${op} ${target_ip1} ${target_ip2} ${intface1} ${intface2}
    	    echo "*** IPERF TEST DONE ***"
    	done
    
    elif [ "${target_ip1}" == "0" ] && [ "${target_ip2}" != "0" ]; then
    echo "The IP1 is empty"
    	for i in "${mtu[@]}"
    	do 
    	    debug "Setting MTU to $i"
    	    ifconfig ${intface2} mtu $i
    	    sleep 3
    	    debug "Set configurations done and Get info MTU of is $i"
    	    debug "*** START TO PERFORM IPERF TESTING ***"
    	    #get_nic_info ${intface2}
    	    sleep 1
    	    iperf_test ${mode} ${op} ${target_ip1} ${target_ip2} ${intface1} ${intface2}
    	    echo "*** IPERF TEST DONE ***"
    	done
    	
    else
        debug "==================================="
        debug "The Dual Port NIC CARD TESTING"
        debug "==================================="
        debug "interface #1 : ${intface1}, IP: ${target_ip1}"
        debug "interface #2 : ${intface2}, IP: ${target_ip2}"
    	for i in "${mtu[@]}"
    	do 
            set_mtu ${intface1} ${i}
            set_mtu ${intface2} ${i}
            #Start to test iperf after configurated MTU done.
    	    iperf_test ${mode} ${op} ${target_ip1} ${target_ip2} ${intface1} ${intface2}
    	    echo "*** IPERF TEST DONE ***"
    	done
    fi
}


function set_link_speed()
{
    intface=$1
    speed=$2
    debug "set_link_speed(): prepare to set speed to ${speed} in INTERFACE to ${intface}" 
    #ethtool -s ${intface} speed ${speed} duplex full autoneg off
	#Should determine if speed setting successful.
    ethtool -s ${intface} speed ${speed} duplex full
    ret=$?
    if [ ${ret} -ne 0 ]; then
        #The link speed set Failed.
        echo "*********** The Link speed set failed. ***********"
    else
        sleep 10
        debug "set_link_speed(): set done and prepare to get configurations to comfirm"
        #get link speed of ethernet interface.
        spd=`ethtool ${intface} | grep -i 'Speed' | cut -d 'M' -f1 | cut -d ' ' -f2`
        if [ "${spd}" != "${speed}" ]; then
            echo "Set Link Speed Failed."
            echo "Current Link Speed is: ${spd}Mbps, Would like to set:${speed}."
            echo -1
        else
            echo "Set Link Speed Success."
            echo "Current Link Speed is: ${spd}Mbps."
        fi
    fi

}

function set_mtu()
{
    intface=$1
    mtu=$2
    debug "set_mtu(): prepare to set MTU to ${mtu} in INTERFACE to ${intface}" 
    ifconfig ${intface} mtu ${mtu}
    sleep 5
    debug "set_mtu(): set done and prepare to get configurations to comfirm"
    get_nic_info ${intface}
}

function usage()
{
    echo "./net_stress_dualport.sh [s / c] [single_port / dual_port / all] [target_ip1] [target_ip2] [interface1] [interface2]"
}

#=================================
#Main() Area
#=================================

if [ -f iperf.log ]; then
    rm iperf.log
fi

if [ $# -lt 3 ]; then
    usage
    exit -1
else
    echo "=========================================="
    echo "CONFIGURATION:"
    echo "=========================================="
    echo "Link Speed:"
    for m in ${speed[@]}
    do 
    	echo "$m Mbps."
    done
    echo "MTU:"
    for m in ${mtu[@]}
    do 
    	echo $m
    done
    echo "Threads:"
    for t in ${thread[@]}
    do
    	echo $t
    done
    echo "${target_ip1}, ${target_ip2}"
    echo "=========================================="
	
    for s in ${speed[@]}
        do
            debug "==================================="
            debug "The Iperf test case starting ..."
		    debug "[LINK SPEED TEST CASE] This Test Case under ${s} Mbps link speed."
		    debug "Setting the link speed of PORT #1 now..."
            set_link_speed ${intface1} ${s}
			if [ "${intface2}" != "0" ]; then 
			    deubg "Setting the link speed of PORT #2 now..."
                set_link_speed ${intface2} ${s}
		    fi
            debug "==================================="
            mtu_test ${mode} ${op} ${target_ip1} ${target_ip2} ${intface1} ${intface2}
        done
	
    echo "TEST SUITE DONE."
    exit 0
fi

