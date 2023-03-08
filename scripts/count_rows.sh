#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

# remove negative durations

count_rows(){
  echo "Total rows in tables"
  echo "table_name|row_count" 
  for t in "${TABLES[@]}"; do
     echo "SELECT COUNT(*) FROM $t;" > $TEMPFILE
     #cat $TEMPFILE
     RES=$(sqlite3 $DB < $TEMPFILE)     
     echo "$t|$RES"
  done
}

count_rows
