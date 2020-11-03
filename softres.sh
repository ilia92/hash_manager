#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"
source $DIR/manager.conf

# Functions
source $DIR/functions/sendtext.func

api_key=`cat "$api_key_file"`

rig_name=$1
rig_line=`cat $DIR/workers.txt | cut -f1 -d"#" | sed '/^\s*$/d' | grep $rig_name`
rig_ip=`printf "$rig_line" | awk {'print $5'}`

if ! `timeout 1 ping -c 1 $rig_ip >/dev/null 2>&1`; then
printf "No ping to machine, exiting\n"
exit
else
printf "No-Power-Restart procedure started in background: sr_$1\n"
fi

if [[ "$STY" !=  *"sr_$1"* ]]; then exec screen -dm -S sr_$1 /bin/bash $0 $1 $2; fi

printf "Stopping and Restarting the rig ...\n"
timeout 10 ssh miner@$rig_ip 'screen -S ethm -X stuff "12" ; sleep 0.5 ; screen -S ethm -X stuff "34" ; sleep 0.5 ; screen -S ethm -X stuff "56" ; sleep 0.5 ; screen -S ethm -X stuff "78" ; sleep 0.5 ; screen -S ethm -X stuff "9a" ; sleep 0.5 ; pkill -9 start.sh ; screen -dm bash -c "sleep 4; echo b > /proc/sysrq-trigger" '

sleep 50
# Make the rechecking and notifying mandatory
sed -i -n "/${rig_name}/!p" $workers_down_file

retries=100
for i in `seq 1 $retries`;
do
if `timeout 0.5 ping -c 1 $rig_ip > /dev/null`; then
printf "$rig_name UP, go ahead\n\n"
break
elif [[ $i -gt $(($retries-1)) ]]; then
message="no ping to $rig_name, exit"
printf "$message\n"
   if [ "$2" == "--notify" ]; then
    sendtext "$message"
    printf "Message was sent!"
   fi
sleep 60
exit
fi
sleep 1
done

sleep 90

ping -c1 $rig_ip >/dev/null 2>&1 && updown="$rig_name is UP" || updown="$rig_name is DOWN"
hash=`timeout 3 curl --silent $rig_ip:3333 | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed \(5 min\): ).*(?=MH/s)'\|'(?<=speed: ).*(?=Mh/s)' | cut -d. -f1`

#without printf - newline in telegram bugs
message=`printf "$updown\nHashrate: $hash"`
printf "$message\n"

if [ "$2" == "--notify" ]; then
sendtext "$message"
printf "Message was sent!"
fi
# Screen stays for 60 seconds
sleep 60

