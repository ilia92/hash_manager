#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

source $DIR/manager.conf

api_key=`cat "$api_key_file"`

workers_down_file="$DIR/.workers_down"

hash_checker_results=`cat "$hash_checker_results_file" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | sed -n '/============================START===========================/,/=============================END============================/p' | grep -v 'START\|END' | awk {'printf $1"   "$2"   "$3"   "$4"\n"'}`

touch "$workers_down_file"
workers_down_content=`cat "$workers_down_file"`

# Check for down workers
if [[ "$hash_checker_results" ]]; then
for i in `seq 1 $(($(printf "$hash_checker_results" | wc -l)+1))`;
do
w_line=`printf "$hash_checker_results" | sed "$i!d"`
w_down_name=`printf "$w_line" | awk {'print $1'}`
w_down_notified_count=`printf "$workers_down_content" | grep "$w_down_name" | awk {'print $2'}`

if ! [[ "$w_down_notified_count" ]]; then
w_down_notified_count=0
echo "$w_down_name 1" >> $workers_down_file

message_new="${message_new}NEW: ${w_line}\n"
elif [ $(($w_down_notified_count+1)) -le $messages_giveup ]; then

w_down_notified_count=$(($w_down_notified_count+1))
sed -i "/${w_down_name}/c${w_down_name}\t$(($w_down_notified_count))" $workers_down_file

message_still="${message_still}STILL: ${w_line}\n"
fi
done
fi
# END Check for new workers down

# Check if miners gone UP
if [[ "$workers_down_content" ]]; then
for j in `seq 1 $(($(printf "$workers_down_content" | wc -l)+1))`;
do
w_potentially_down=`printf "$workers_down_content" | sed "$j!d" | awk {'print $1'}`
if_gone_up=`printf "$hash_checker_results" | grep "$w_potentially_down"`

if ! [[ $if_gone_up ]]; then
message_up="${message_up}UP: $w_potentially_down\n"
sed -i -n "/${w_potentially_down}/!p" $workers_down_file
fi
done
fi
# END Check if miners gone UP

if [[ $message_new ]] || [[ $message_still ]] || [[ $message_up ]]; then

message_tail=`cat "$hash_checker_results_file" | grep "SUM\|Active"`
message=`printf "${message_new}${message_still}${message_up}\n${message_tail}"`

printf "Message:\n$message\n"
curl --silent  -X POST https://api.telegram.org/bot$api_key/sendMessage -d chat_id="$chat_id" -d text="$message"  >/dev/null 2>&1 &
else
printf "Empty message!\n"
fi
