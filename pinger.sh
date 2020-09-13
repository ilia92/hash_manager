#!/bin/bash

rig=$1

machine=`echo $1 | sed 's|r||g'`
o=`echo $machine | grep -o '^..'`
n=`echo $machine | grep -o '..$' `

#printf "machine: $machine \no: $o\nn: $n\n"

ping -c1 192.168.$o.$n >/dev/null 2>&1 && printf "$rig is UP\n" || printf "$rig still DOWN\n"
hash=`timeout 1 curl --silent 192.168.$o.$n:3333 | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed \(5 min\): ).*(?=MH/s)'\|'(?<=speed: ).*(?=Mh/s)' | cut -d. -f1`
printf "Hashrate: $hash\n"

