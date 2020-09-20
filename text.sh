DIR="$(dirname "$(readlink -f "$0")")"
source $DIR/manager.conf

api_key=`cat "$api_key_file"`


source ./functions/sendtext.func

opop="test\nopop"

opop="$opop"
sendtext "$opop"
