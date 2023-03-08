#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

# seems that the only duplicates we might care is with ride_id
echo "table_name max_len_ride_id min_len_ride_id"
for t in "${TABLES[@]}"; do
  echo "SELECT MAX(LENGTH(ride_id)) AS max_len_ride_id, MIN(LENGTH(ride_id)) FROM $t;" > $TEMPFILE
  #cat $TEMPFILE 
  RES=$(sqlite3 bikeshares.sqlite < $TEMPFILE)
  echo "$t $RES"
done
