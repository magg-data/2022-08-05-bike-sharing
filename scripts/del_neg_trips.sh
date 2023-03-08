#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

# remove negative durations

del_neg_durations(){
  echo "Removing negative duration trips" 
  for t in "${TABLES[@]}"; do
     echo "DELETE FROM $t WHERE ended_at < started_at ;" > $TEMPFILE
     #cat $TEMPFILE
     RES=$(sqlite3 $DB < $TEMPFILE)     
  done
}

del_neg_durations