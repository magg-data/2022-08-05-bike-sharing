#!/bin/bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

for t in "${TABLES[@]}"; do
  TEMPFILE=$(mktemp)
  echo "SELECT MAX(same_loc) FROM (SELECT ride_id, start_lat, start_lng, end_lat, end_lng, COUNT(*) AS same_loc FROM $t WHERE LENGTH(start_station_name)=0 GROUP BY start_lat, start_lng, end_lat, end_lng)" > $TEMPFILE
  #cat $TEMPFILE
  COUNT=$(sqlite3 bikeshares.sqlite < $TEMPFILE)
  echo $t|$COUNT
done
