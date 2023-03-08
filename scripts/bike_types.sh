#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

# identify the bike_types

for t in "${TABLES[@]}"; do
  echo "SELECT rideable_type, COUNT(rideable_type) FROM $t GROUP BY rideable_type;" > $TEMPFILE
  #cat $TEMPFILE 
  RES=$(sqlite3 $DB < $TEMPFILE)
  echo "$t"
  echo "$RES"
  
  echo "SELECT row_no FROM $X_TOTROWS WHERE table_name = \"$t\";" > $TEMPFILE
  #cat $TEMPFILE
  RES1=$(sqlite3 $DB < $TEMPFILE)
  
  echo "SELECT SUM(bike_type) FROM (SELECT COUNT(ride_id) as bike_type FROM $t GROUP BY rideable_type)" > $TEMPFILE
  #cat $TEMPFILE
  RES2=$(sqlite3 $DB < $TEMPFILE)
  
  if [ $RES1 -ne $RES2 ] ; then
	echo "Error $tc;: row_count=$RES1 sum=$RES2"
  fi
done
