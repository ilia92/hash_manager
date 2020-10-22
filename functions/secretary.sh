#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"


#Default data



source $DIR/setup.conf
source $DIR/sendtext.func



if [ -z "$STY" ]; then
printf "Bot started in background\n"
screen -S stats_bot -X quit > /dev/null
exec screen -dm -S stats_bot /bin/bash $0
fi


help_section="
/stats - Get all updated settings
/reward - Check current ETH Block Reward
/auto_switch - ON or OFF - Switch automatically the pool when desired reward is met
/set-desired-reward - set desired reward
/set-desired-pool - set desired reward
/set-current-pool - set the current pool manually
"

while [ 1 ]
do

CURRENT_REWARD=`cat $DIR/../global_vars/.current_reward`
AUTO_SWITCH=`cat $DIR/../global_vars/.pool_auto_switch`
DESIRED_REWARD=`cat $DIR/../global_vars/.desired_reward`
DESIRED_POOL=`cat $DIR/../global_vars/.desired_pool`
CURRENT_POOL=`cat $DIR/../global_vars/.current_pool`


curr_message=`curl --silent -s "https://api.telegram.org/bot$api_key/getUpdates?timeout=600&offset=$update_id"`
last_upd_id=`printf "$curr_message" |  jq '.result | .[] | .update_id' | tail -1`

if [[ $update_id -le $last_upd_id ]]; then
update_id=$((last_upd_id+1))

curr_message_text=`printf "$curr_message" | jq -r '.result | .[].message.text' | tail -1`

if [[ "$curr_message_text" ]]; then
printf "Message received: $curr_message_text\n"
# clear last message
curl -s "https://api.telegram.org/bot$api_key/getUpdates?offset=$update_id"  >/dev/null 2>&1
fi

command=`echo $curr_message_text | grep -o '\/.*' | awk {'print $1'} | sed "s|@$username||g"`
arg=`echo $curr_message_text | awk {'print $2" "$3" "$4'}`

case "$command" in
	("") ;;
	("/reward") sendtext "ETH Block Reward: $CURRENT_REWARD";;
	("/stats") 
		sendtext "Current reward is $CURRENT_REWARD"
		sendtext "Desired reward is $DESIRED_REWARD"
		sendtext "Current pool is $CURRENT_POOL"
		sendtext "Desired pool is $DESIRED_POOL"
		sendtext "Autoswitch is set to $AUTO_SWITCH"
		result = "done!"
	 ;;
	("/help") result="$help_section" ;;

	("/set-desired-reward") echo $arg > $DIR/../global_vars/.desired_reward;;
	("/set-desired-pool") echo $arg > $DIR/../global_vars/.desired_pool;;
	("/set-current-pool") echo $arg > $DIR/../global_vars/.current_pool;;
	("/auto_switch") echo $arg > $DIR/../global_vars/.pool_auto_switch;;

	(*) result="Unknown command!" ;;
esac

if [[ "$result" ]]; then
#printf "Result:\n$result"
sendtext "$result"

fi

printf "\n\n"
fi


sleep 5

done
