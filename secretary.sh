#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

source $DIR/manager.conf
api_key=`cat "$api_key_file"`

if [ -z "$STY" ]; then printf "Bot started in background\n" ; screen -S secretary_bot -X quit ; exec screen -dm -S secretary_bot /bin/bash $0 ; fi

refresh_rate=1

curl --silent https://api.telegram.org/bot$api_key/getMe | jq
username=`curl --silent https://api.telegram.org/bot$api_key/getMe | jq -M -r .result.username`
date

help_section="
/help - Prints this text
/pinger name - Check if rig is UP
/rigres name - Restarts rig
/full - Check all rigs
/recheck - Rechecks rig hashrate
/renull - Clear memory and start notifying again
/cache - Shows cached results
"

sendtext() {
curl -X POST https://api.telegram.org/bot$api_key/sendMessage -d chat_id=$chat_id -d text="$1" >/dev/null 2>&1 ;
}

while [ 1 ]
do

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
arg=`echo $curr_message_text | awk {'print $2'}`

#printf "$command and $arg"

case "$command" in
	("") ;;
	("/test") result="test PASS!" ;;
        ("/help") result="$help_section" ;;
        ("/pinger") result=`$DIR/pinger.sh $arg` ;;
        ("/rigres") sendtext "Sending restart procedure ..." ; $DIR/rigres.sh $arg --no-send ; result=`$DIR/pinger.sh $arg` ;;
        ("/full") result=`$DIR/hash_checker.sh --full | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | grep -v GENERATED | awk {'printf $1"   "$2"   "$3"   "$4"\n"'} | sed '/=START=/c\\n'| sed '/=END=/c\\n'` ;;
        ("/recheck") $DIR/hash_checker.sh ; $DIR/telegram_notifier.sh ;;
        ("/renull") rm $DIR/.workers_down ; $DIR/hash_checker.sh ; $DIR/telegram_notifier.sh ;;
        ("/cache") result=`cat $DIR/cache.txt | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | awk {'printf $1"   "$2"   "$3"   "$4"\n"'} | sed '/=START=/c\\n'| sed '/=END=/c\\n'` ;;
#        ("/routeadd")result=` ./routeadd.sh` ;;
	(*) result="Unknown command!" ;;
esac

if [[ "$result" ]]; then
#printf "Result:\n$result"
sendtext "$result"
fi

printf "\n\n"
fi

sleep $refresh_rate
done

