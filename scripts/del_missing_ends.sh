#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

# remove rows where we can't identify the endpoints
del_missing_endpoints(){
  echo "Removing trips with unidentifiable end_stations" 
  for t in "${TABLES[@]}"; do
     echo "DELETE FROM $t " > $TEMPFILE
     echo "   WHERE (LENGTH(end_station_id) = 0) " >> $TEMPFILE
     echo "       AND (LENGTH(end_station_name) = 0) " >> $TEMPFILE
     echo "       AND (LENGTH(end_lat) = 0 OR LENGTH(end_lng) = 0);" >> $TEMPFILE
     #cat $TEMPFILE
     RES=$(sqlite3 $DB < $TEMPFILE)     
  done
}

del_missing_endpoints