#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

workers_file=workers.txt
workers_file_read=`cat $DIR/$workers_file | cut -f1 -d"#" | sed '/^\s*$/d' | grep -v win`

criteria="$1"
ips_file=$DIR/parallels/${criteria}.txt

# The script imports predefined pools and example wallets
source $DIR/pools_and_wallets.txt

if ! [[ $criteria ]] || [[ $criteria == "--help" ]]; then
printf "Usage: ./pool_switcher.sh [criteria/all] [pool_url] [wallet]\n"
exit
fi

# Check for predefined

if [ $( printf "$pools"| grep "$2" | wc -l ) == 1 ]; then
pool=`printf "$pools"| grep "$2"`
else
pool="$2"
fi

if [ $( printf "$wallets" | grep "$3" | wc -l ) == 1 ]; then
wallet=`printf "$wallets" | grep "$3"`
else
wallet="$3"
fi
# END Check for predined

# The next IF checks for legit input
if ! [[ "$pool" == *":"???* ]] || ! ( [[ ${#wallet} -eq 42 ]] || [[ ${#wallet} -eq 40 ]] );then
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

printf "The following parameters are used: $1 $pool $wallet\n"

parallel-ssh -t 15 -h $ips_file "sed -i '/pool/c\pool=\"$pool\"' ~/rig_wallet ; sed -i '/wallet/c\wallet=\"$wallet\"' ~/rig_wallet; ./miner_launcher.sh"
