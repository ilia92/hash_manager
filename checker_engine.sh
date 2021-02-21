#/bin/bash

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="$(dirname "$(readlink -f "$0")")"

source $DIR/manager.conf

workers_file=workers.txt

if [ "$1" = "--only" ]; then
	if ! [ $2 ]; then
	printf "After only should be name for GREP-ing\n"
	exit 1
	fi
only=$2
else
only='.'
fi

workers_file_read=`cat $DIR/$workers_file | cut -f1 -d"#" | sed '/^\s*$/d' | grep $only`

workers_count=`printf "$workers_file_read" | wc -l`

curl_min_hash_a[$workers_count]=0

hash_loss=0
hash_target_full=0
hash_curl_full=0
w_down=0
excluded_hash=0

if [ "$*" != "--short" ]; then

>&2 printf "Please wait to get the results\n"

fi

foo() {
#curl_min_hash_a[$j]=`timeout $curl_timeout curl --silent $w_ip_port | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed: ).*(?=Mh/s)'| cut -d. -f1 &`
curl_min_hash_a[$j]=`timeout $curl_timeout curl --silent $w_ip_port | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed \(5 min\): ).*(?=MH/s)'\|'(?<=speed: ).*(?=Mh/s)' | cut -d. -f1`
if ! [[ ${curl_min_hash_a[$j]} ]]; then
# printf "TRM miner\n"
 w_ip_port=`echo "$w_ip_port" | sed "s|:| |g"`
 curl_min_hash_a[$j]=`echo summary | nc -w 2 $w_ip_port | grep -o -P '(?<=30s=).*(?=,KHS av)' | cut -d. -f1`
fi
}

for j in `seq 1 $(($workers_count+1))`;

        do
#	sleep 0.2
	if [ "$*" != "--short" ]; then
	>&2 printf "."
	fi
        line=`printf "$workers_file_read" | sed "$j!d" `

        w_name=`printf "$line" | awk '{printf $1}'`
#        w_cards=`printf "$line" | awk '{printf $3}'`
        w_target=`printf "$line" | awk '{printf $4}'`
        w_ip=`printf "$line" | awk '{printf $5}'`

        if ! [ `printf "$w_ip" | grep ":" ` ]; then
        w_ip_port=`printf "$w_ip:3333"`
        else
        w_ip_port=$w_ip
        fi

# Excluders
        if [[ `printf "$line" | grep "\-\-exclude"` ]]; then
	excluded_hash=$(($w_target+$excluded_hash))
	printf "\e[34m$w_name\e[0m"
        fi
# END Excluders

        hash_target_full=$(($w_target+$hash_target_full))

foo 
done
>&2 printf "\n"

if [ "$*" != "--short" ]; then

printf "GENERATED AT:  "
date +"%H:%M %e-%b-%y"
printf "\n"
printf "Worker\t\tTarget\tDiff\t(perc)\tIP\n"
printf "============================START===========================\n"

fi

wait

for i in `seq 1 $(($workers_count+1))`;

        do
	line=`printf "$workers_file_read" | sed "$i!d" `

	w_name=`printf "$line" | awk '{printf $1}'`
	w_cards=`printf "$line" | awk '{printf $3}'`
	w_target=`printf "$line" | awk '{printf $4}'`
	w_ip=`printf "$line" | awk '{printf $5}'`

		if [ "$w_name" ] && [ "$w_target" ] && [ "$w_ip" ]; then


#printf "\n \n "

		curl_min_hash=${curl_min_hash_a[$i]}

		hash_curl_full=$(($curl_min_hash+$hash_curl_full))

		hash_diff=$(($curl_min_hash-$w_target))
#			if [ $hash_diff -lt 0 ]; then
			hash_loss=$(($hash_loss+$hash_diff))
#			fi
			hash_diff_perc=$(($hash_diff*100 / $w_target))
			if [ $hash_diff_perc -lt -4 ]; then
				if [ $hash_diff_perc -eq -100 ]; then

                        printf "\033[0;41m$w_name\t\t$w_target\t$hash_diff\t$hash_diff_perc\t$w_ip\e[0m\n"

			w_down=$((w_down + 1))
				else
			printf "$w_name\t\t$w_target\t$hash_diff\t$hash_diff_perc\t$w_ip\n"
				fi
			elif [ "$*" = "--full" ]; then
                        printf "$w_name\t\t$w_target\t$hash_diff\t$hash_diff_perc\t$w_ip\n"

#			else
#			printf "RIG OK\n"
			fi
		else
                printf "==========================================\n"
                printf "Worker name:\t$w_name\n"
		printf "Info not full! Check rig list - $workers_file!\n"
		fi

done

if [ "$*" != "--short" ]; then
printf "=============================END============================\n"

hash_target_full=$(($hash_target_full-$excluded_hash))
hash_curl_full=$(($hash_curl_full-$excluded_hash))
hash_diff_perc_full=$(($hash_loss*100 / $hash_target_full))

printf "SUM:\t\t$hash_target_full\t$hash_loss\t$hash_diff_perc_full\tDown: $w_down\n"

printf "Active: $hash_curl_full\n"

if [ $excluded_hash -ne 0 ]; then
printf "\n\n"
printf "=============================================================\n"
printf "Excluded hash: \t\t\t $excluded_hash\n"
printf "=============================================================\n"
fi
fi
