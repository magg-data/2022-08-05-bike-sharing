#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

function string() {
  local FIELD=$1
  local NAME=$2
  return "MAX($FIELD) AS max_$NAME, MIN($FIELD) AS min_$NAME"
}

function general() {
  echo "What are start and end min  and max values for lat and lng?"
  echo "table_name|max_start_lat|min_start_lat|max_start_lng|min_start_lng|max_end_lat|min_end_lat|max_end_lng|min_end_lng"
  for t in "${TABLES[@]}"; do
    echo "SELECT MAX(CAST(start_lat AS REAL)) AS max_st_lat, MIN(CAST(start_lat AS REAL)) AS min_st_lat," > $TEMPFILE
    echo "       MAX(CAST(start_lng AS REAL)) AS max_st_lng, MIN(CAST(start_lng AS REAL)) AS min_st_lng," >> $TEMPFILE
    echo "       MAX(CAST(end_lat AS REAL)) AS max_end_lat, MIN(CAST(end_lat AS REAL)) AS min_end_lat," >> $TEMPFILE
    echo "       MAX(CAST(end_lng AS REAL)) AS max_end_lng, MIN(CAST(end_lng AS REAL)) AS min_end_lng" >> $TEMPFILE
    echo "FROM $t;" >> $TEMPFILE
    #cat $TEMPFILE 
    RES=$(sqlite3 $DB < $TEMPFILE)
    echo "$t|$RES"
  done
}

function end_stations() {
  echo "How many rows have neither end_station_id nor end_station_name nor the (lat,lng)"
  echo "table_name|rows_count"
  for t in "${TABLES[@]}"; do
    echo "SELECT COUNT(*) FROM $t WHERE (LENGTH(end_station_id) = 0) " > $TEMPFILE
    echo "       AND (LENGTH(end_station_name) = 0) " >> $TEMPFILE
    echo "       AND (LENGTH(end_lat) = 0 OR LENGTH(end_lng) = 0);" >> $TEMPFILE
    #cat $TEMPFILE 
    RES=$(sqlite3 $DB < $TEMPFILE)
    echo "$t|$RES"
  done
}

function select_fields() {
  local TABLE=$1
  echo "SELECT start_station_id, start_station_name, start_lng, start_lat FROM $TABLE UNION SELECT end_station_id, end_station_name, end_lng, end_lat FROM $TABLE"
}

function select_stations() {
  
  echo "Select stations, their ids, longtitudes and latitudes"
  cat /dev/null > $TEMPFILE

  for t in "${TABLES[@]}"; do
    #local RES=$(select_fields $t)
    local RES=`select_fields $t`
    local FIRST=${TABLES[0]}
    if [ "$t" = "$FIRST" ]; then
      RES="SELECT start_station_id AS id, start_station_name AS name, start_lng AS lng, start_lat AS lat FROM $t UNION SELECT end_station_id, end_station_name, end_lng, end_lat FROM $t"
    fi

    # treat the last element is different     
    # ${TABLES[@]} - number of elements
    local LAST=${TABLES[${#TABLES[@]}-1]}
    if [ "$t" = "$LAST" ] ; then
      echo "$RES;" >> $TEMPFILE      
    else
      echo "$RES UNION " >> $TEMPFILE
    fi
  done

  cat $TEMPFILE
  RES=$(sqlite3 $DB < $TEMPFILE)
  echo $RES > stations.txt

  # select start_station_id, start_station_name, min(start_lat), max(start_lat), min(start_lng), max(start_lng) from b_202201 group by start_station_name;
}

# $1 - should be either "start" or "end"
function count_empty_names() {
  echo "Counts rows with empty $start_station_id"
  
  echo "table_name|rows_count"
  for t in "${TABLES[@]}"; do
    echo "SELECT * FROM $t WHERE (LENGTH(start_station_name) = 0 AND LENGTH(start_station_id) != 0);" > $TEMPFILE

    #cat $TEMPFILE 
    RES=$(sqlite3 $DB < $TEMPFILE)
    echo "$t|$RES"
  done
}

#general
#end_stations
#select_stations
#count_empty_names