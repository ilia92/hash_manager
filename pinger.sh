#!/bin/bash

rig=$1
DIR="$(dirname "$(readlink -f "$0")")"

machine=`echo $1 | sed 's|r||g'`
o=`echo $machine | grep -o '^..'`
n=`echo $machine | grep -o '..$' | sed 's|^0||g'`

ip=192.168.$o.$n

#printf "machine: $machine \no: $o\nn: $n\n"

updown=`timeout 1 ping -c1 $ip >/dev/null 2>&1 && printf "$rig is UP\n" || printf "$rig is DOWN\n"`
hash=`timeout 3 curl --silent 192.168.$o.$n:3333 | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed \(5 min\): ).*(?=MH/s)'\|'(?<=speed: ).*(?=Mh/s)' | cut -d. -f1`

printf "$updown\nHashrate: $hash\n"

