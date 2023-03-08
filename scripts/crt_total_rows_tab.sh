#!/bin/bash

# run it only once after you create the db from bikeshares csv files
# not sure if sqlite3 respects create if not exists
# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

# drop table $X_TOTROWS;

# creates the new table with counted rows
echo "CREATE TABLE IF NOT EXISTS $X_TOTROWS( table_name TEXT, row_no INTEGER );" > $TEMPFILE
#cat $TEMPFILE
RES=$(sqlite3 $DB < $TEMPFILE)

for t in "${TABLES[@]}"; do
  echo "SELECT COUNT(*) FROM $t;" > $TEMPFILE
  #cat $TEMPFILE 
  RES=$(sqlite3 $DB < $TEMPFILE)
  #echo $RES
  echo "INSERT INTO  $X_TOTROWS (table_name, row_no)  VALUES (\"$t\", $RES);" > $TEMPFILE
  cat $TEMPFILE 
  $(sqlite3 $DB < $TEMPFILE)
  #echo "Inserted: $t $RES"
done
