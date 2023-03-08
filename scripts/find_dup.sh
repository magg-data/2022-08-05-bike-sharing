#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

# seems that the only duplicates we might care is with ride_id

for t in "${TABLES[@]}"; do
  echo "SELECT COUNT(ride_id) FROM $t;" > $TEMPFILE
  #cat $TEMPFILE 
  RES=$(sqlite3 bikeshares.sqlite < $TEMPFILE)
  echo "SELECT COUNT(DISTINCT ride_id) FROM $t;" > $TEMPFILE
  #cat $TEMPFILE
  RESDISTINCT=$(sqlite3 bikeshares.sqlite < $TEMPFILE)
  
  if [ $RES != $RESDISTINCT ] ; then
	echo "-----> DUPLICATES FOUND for ride_id: $t: $RES $RESDISTINCT"
  else
    echo "NO DUPLICATES FOUND in $t for ride_id"
  fi
done
