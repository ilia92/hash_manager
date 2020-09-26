#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

workers_file=workers.txt
workers_file_read=`cat $DIR/$workers_file | cut -f1 -d"#" | sed '/^\s*$/d' | grep -v win`

criteria="$1"
ips_file=$DIR/parallels/${criteria}.txt

if ! [[ $criteria ]] || [[ $criteria == "--help" ]]; then
printf "Usage: ./pool_switcher.sh [criteria/all] [pool_url] [wallet]\n"
exit
fi

# The next IF checks for legit input
if ! [[ "$2" == *":"???* ]] || ! ( [[ ${#3} -eq 42 ]] || [[ ${#3} -eq 40 ]] );then
printf "Bad input!\n"
printf "Usage: ./pool_switcher.sh [criteria/all] [pool_url] [wallet]\n"
exit
fi

if [[ $criteria == "all" ]]; then
workers_ips=`printf "$workers_file_read" | awk {'print $5'}`
else
workers_ips=`printf "$workers_file_read" | grep "$criteria" | awk {'print $5'}`
fi

printf "$workers_ips\n" > $ips_file

parallel-ssh -o "StrictHostKeyChecking=no" -h $ips_file "sed -i '/pool/c\pool=\"$2\"' ~/rig_wallet ; sed -i '/wallet/c\wallet=\"$3\"' ~/rig_wallet; ./miner_launcher.sh"
