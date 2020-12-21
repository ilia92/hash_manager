#!/bin/bash

#rig=$1
DIR="$(dirname "$(readlink -f "$0")")"

rig_name=$1
rig_line=`cat $DIR/workers.txt | cut -f1 -d"#" | sed '/^\s*$/d' | grep $rig_name`
rig_ip=`printf "$rig_line" | awk {'print $5'}`

#printf "machine: $machine \no: $o\nn: $n\n"

updown=`timeout 1 ping -c1 $rig_ip >/dev/null 2>&1 && printf "$rig_name is UP\n" || printf "$rig_name is DOWN\n"`
hash=`timeout 3 curl --silent $rig_ip:3333 | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed \(5 min\): ).*(?=MH/s)'\|'(?<=speed: ).*(?=Mh/s)' | cut -d. -f1`

printf "$updown\nHashrate: $hash\n"

