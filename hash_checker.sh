#/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

source $DIR/manager.conf

bash $DIR/checker_engine.sh | tee "$cache_file"
# Change permissions - to be readable from php
chmod 666 "$cache_file" 2> /dev/null
