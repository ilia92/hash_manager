#/bin/bash

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="$(dirname "$(readlink -f "$0")")"

workers_file=workers.txt
curl_time=2

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

printf "\nPlease wait to get the results\n"

foo() {
#curl_min_hash_a[$j]=`timeout $curl_time curl --silent $w_ip_port | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed: ).*(?=Mh/s)'| cut -d. -f1 &`
curl_min_hash_a[$j]=`timeout $curl_time curl --silent $w_ip_port | html2text -width 200 | grep "1 minute average\|Average speed" | tail -1 | grep -o -P '(?<=speed \(5 min\): ).*(?=MH/s)'\|'(?<=speed: ).*(?=Mh/s)' | cut -d. -f1`
}

for j in `seq 1 $(($workers_count+1))`;

        do
#	sleep 0.2
	printf "."
        line=`printf "$workers_file_read" | sed "$j!d" `

        w_name=`printf "$line" | awk '{printf $1}'`
#        w_type=`printf "$line" | awk '{printf $2}'`
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

printf "\n\nResults are taken, wait the $curl_time seconds timeout and checking ...\n\n"

wait

#sleep $curl_time;

for i in `seq 1 $(($workers_count+1))`;

        do
	line=`printf "$workers_file_read" | sed "$i!d" `

	w_name=`printf "$line" | awk '{printf $1}'`
	w_type=`printf "$line" | awk '{printf $2}'`
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
			hash_diff_proc=$(($hash_diff*100 / $w_target))
			if [ $hash_diff_proc -lt -4 ]; then
				if [ $hash_diff_proc -eq -100 ]; then

                        printf "==========================================\n"
#			printf "\033[0;41m"
                        printf "\033[0;41mWorker name:\t$w_name\e[0m\n"
                        printf "\033[0;41mIP address:\t$w_ip\e[0m\n"
                        printf "\033[0;41mHash difference:\t $hash_diff\e[0m\n"
                        printf "\033[0;41mHash diff (percent) :\t $hash_diff_proc %%\e[0m\n"

			w_down=$((w_down + 1))
				else
                        printf "==========================================\n"
                        printf "Worker name:\t$w_name\n"
                        printf "IP address:\t$w_ip\n"
                        printf "Hash difference:\t $hash_diff\n"
                        printf "Hash diff (percent) :\t $hash_diff_proc %% \n"
				fi
			elif [ "$1" = "--full" ] || [ "$3" = "--full" ]; then
                        printf "==========================================\n"
                        printf "Worker name:\t$w_name\n"
                        printf "IP address:\t$w_ip\n"
                        printf "Hash difference:\t $hash_diff\n"
                        printf "Hash diff (percent) :\t $hash_diff_proc %% \n"
#			else
#			printf "RIG OK\n"
			fi
		else
                printf "==========================================\n"
                printf "Worker name:\t$w_name\n"
		printf "Info not full! Check rig list - $workers_file!\n"
		fi

done

printf "=============================================================\n"
printf "Statistics:\n"

hash_target_full=$(($hash_target_full-$excluded_hash))
hash_curl_full=$(($hash_curl_full-$excluded_hash))

printf "Target hashrate (full):\t\t $hash_target_full\n"
printf "RIGs actual hashrate (full):\t $hash_curl_full\n"
printf "Hashrate LOSS:\t\t\t $hash_loss\n"
printf "Workers down: \t\t\t $w_down\n"

printf "=============================================================\n"
printf "Excluded hash: \t\t\t $excluded_hash\n"
printf "=============================================================\n"

