#!/bin/bash

#if [ -z "$STY" ]; then exec screen -dm -S rigres /bin/bash $0 $1 ; fi

DIR="$(dirname "$(readlink -f "$0")")"
source $DIR/manager.conf

api_key=`cat "$api_key_file"`

rig_name=$1
rig_line=`cat $DIR/workers.txt | cut -f1 -d"#" | sed '/^\s*$/d' | grep $rig_name`
rig_ip=`printf "$rig_line" | awk {'print $5'}`
sonoff_ip=`printf "$rig_line" | awk {'print $6'}`

if ! `timeout 0.5 ping -c 1 $sonoff_ip >/dev/null 2>&1`; then
printf "No ping to restarter, exiting\n"
exit
fi

printf "Turning OFF the rig ...\n"

timeout 10 ssh miner@$rig_ip 'screen -S ethm -X stuff "12" ; sleep 0.5 ; screen -S ethm -X stuff "34" ; sleep 0.5 ; screen -S ethm -X stuff "56" ; sleep 0.5 ; screen -S ethm -X stuff "78" ; sleep 0.5 ; screen -S ethm -X stuff "9a" ; sleep 0.5 ; pkill -9 start.sh ; screen -dm bash -c "sleep 2; echo o > /proc/sysrq-trigger"'

printf "\nPowering OFF: "
sleep 30
curl http://$sonoff_ip/cm?cmnd=Power%200
sleep 50
printf "\nPowering ON: "
curl http://$sonoff_ip/cm?cmnd=Power%201
printf "\n\n"
sleep 50

retries=100
for i in `seq 1 $retries`;
do
if `timeout 0.5 ping -c 1 $rig_ip > /dev/null`; then
#printf "$rig_name UP, go ahead\n\n"
break
elif [[ $i -gt $(($retries-1)) ]]; then
printf "no ping, exit\n"
exit
fi
sleep 1
done

printf "$rig_name is ONLINE\n\n"

sleep 90

hash=`timeout 1 curl --silent $rig_ip:3333 | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed \(5 min\): ).*(?=MH/s)'\|'(?<=speed: ).*(?=Mh/s)' | cut -d. -f1`

printf "Hashrate: $hash\n"

text=`printf "$rig is ONLINE\nHashrate: $hash\n"`

if [[ $2 == "--no-send" ]]; then
printf "$text"
exit
fi

