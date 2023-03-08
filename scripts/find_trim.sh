#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

for t in "${TABLES[@]}"; do
  #echo "Checking table=$t"
  for f in "${TXTFIELDS[@]}"; do
	echo "SELECT * FROM $t WHERE LENGTH($f) != LENGTH(TRIM($f));" > $TEMPFILE
	cat $TEMPFILE
	RES=$(sqlite3 $DB < $TEMPFILE)
	if [ -n "$RES" ] ; then
		echo "$t: $RES"
	fi
  done
done
