#!/bin/bash

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

TEMPFILE=$(mktemp)

sql_query(){
  # description of the table
  DESC=$1
  # function to use for fields started_at and ended_at
  FUNC=$2

  echo "$DESC"
  echo "table_name|min_start|max_start|min_end|max_end"
  for t in "${TABLES[@]}"; do

    echo "SELECT MIN($FUNC(started_at)) AS min_start, MAX($FUNC(started_at)) AS max_start, MIN($FUNC(ended_at)) AS min_end, MAX($FUNC(ended_at)) AS max_end FROM $t;" > $TEMPFILE
    #cat $TEMPFILE
    RES=$(sqlite3 $DB < $TEMPFILE)
    echo "$t|$RES"
  done
}

#sql_query "Min-max entire dates: started_at and ended_at" "DATETIME"
#sql_query "Min-max dates: started_at and ended_at" "DATE"
#sql_query "Min-max times: started_at and ended_at" "TIME"

negative_durations(){
  echo "How many negative trips"
  echo "table_name|count (<0)|min_duration[s]|max_duration[s]"
  for t in "${TABLES[@]}"; do
     echo "SELECT COUNT(*) AS negative_durations, ROUND(MAX((julianday(ended_at) - julianday(started_at)) * 86400.0)) AS min_duration, ROUND(MIN((julianday(ended_at) - julianday(started_at))*86400.0)) AS max_duration FROM $t WHERE ended_at < started_at ;" > $TEMPFILE
     #cat $TEMPFILE
     RES=$(sqlite3 $DB < $TEMPFILE)
     echo "$t|$RES"
  done
  echo "By how many seconds and which trip has a negative duration"
  echo "table_name|ride_id|started_at|ended_at|duration[sec](<0)"
  for t in "${TABLES[@]}"; do
     echo "SELECT ride_id, started_at, ended_at, (julianday(ended_at) - julianday(started_at))*86400.0 AS delta FROM $t WHERE ended_at < started_at ORDER BY delta;" > $TEMPFILE
     #cat $TEMPFILE
     RES=$(sqlite3 $DB < $TEMPFILE)
     echo "$t"
     echo "$RES"
  done
}

negative_durations

# the duration is computed in days; multiply by 24.0 to get hours, 1440.0 to get mins or by 86400.0 to get seconds
#select count(*) from b_202205 where (julianday(ended_at) - julianday(started_at)) <= 0;

# how many trips lasted how many days
#select round((julianday(ended_at) - julianday(started_at))) as duration_in_days, count(*) from b_202205 group by duration_in_days;

# how many trips grouped by hours of duration
#select round((julianday(ended_at) - julianday(started_at))*24.0) as duration_in_hours, count(*) from b_202205 group by duration_in_hours order by duration_in_hours desc;

# group by minutes
#select round((julianday(ended_at) - julianday(started_at))*1440.0) as duration_in_min, count(*) from b_202205 group by duration_in_min order by duration_in_min desc;
