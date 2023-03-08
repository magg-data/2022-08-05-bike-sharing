#!/bin/bash

# date: 07/31/2022 - the file does not work
# I couldn't run it and run the tr command
# apparently it removed 
#  tr -d '^M' < analysis.sh1 > analysis.sh

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

function crt_duration_view {
  local TEMPFILE=$(mktemp)

  echo "Create a view for researching the durations "
  # start - started_at
  # end - ended_at
  # hours - duration in hours
  # mins - duration in minutes
  # mem - member_casual - m for member and c for casual - the original
  #       member_casual is ended with CR 0D (check hex(member_casual))
  #       and it confuses sqlite
cat <<SQL_QUERY > $TEMPFILE
CREATE VIEW ${V_DURATIONS} (start, end, hours, mins, secs, mem) AS
SQL_QUERY

  # ${TABLES[@]} - number of elements  
  local FIRST=${TABLES[0]}
  local LAST=${TABLES[${#TABLES[@]}-1]}
  
  local QRY="UNION SELECT started_at, ended_at, ROUND((julianday(ended_at) - julianday(started_at)) * 24.0, 1), ROUND((julianday(ended_at) - julianday(started_at)) * 1440.0, 0), ROUND((julianday(ended_at) - julianday(started_at)) * 86400.0, 0), SUBSTR(member_casual, 1, 1) FROM "

  for t in "${TABLES[@]}"; do
    # multiply by 24.0 to get hours, 1440.0 to get mins or by 86400.0 to get seconds
  
    if [ "$t" = "$FIRST" ]; then
cat <<SQL_QUERY >> $TEMPFILE
  SELECT started_at, ended_at, 
     ROUND((julianday(ended_at) - julianday(started_at)) * 24.0, 1) AS hours,
     ROUND((julianday(ended_at) - julianday(started_at)) * 1440.0, 0) AS mins, 
     ROUND((julianday(ended_at) - julianday(started_at)) * 86400.0, 0) AS secs,
     SUBSTR(member_casual, 1, 1) AS mem
  FROM ${t}
SQL_QUERY
    elif [ "$t" = "$LAST" ] ; then
      echo "$QRY $t;" >> $TEMPFILE      
    else
      echo "$QRY $t " >> $TEMPFILE
    fi
done
    #cat $TEMPFILE 
    $(sqlite3  $DB < $TEMPFILE)    
}
#crt_duration_view

# create a view with more than 5 min trips
function crt_5minplus_view {
  local TEMPFILE=$(mktemp)

  echo "Create a view for researching the durations but skip everything <= 5min"
  # start - started_at
  # end - ended_at
  # hours - duration in hours
  # mins - duration in minutes
  # mem - member_casual - m for member and c for casual - the original
  #       member_casual is ended with CR 0D (check hex(member_casual))
  #       an it confuses sqlite
cat <<SQL_QUERY > $TEMPFILE
CREATE VIEW ${V_5MINUP_DURATIONS} (start, end, hours, mins, secs, mem) AS
SELECT start, end, hours, mins, secs, mem FROM ${V_DURATIONS}
WHERE mins > 5;
SQL_QUERY
    #cat $TEMPFILE 
    $(sqlite3  $DB < $TEMPFILE)    
}
#crt_5minplus_view

# ----------------------------------
# by default all other functions require $V_5INUP_DURATIONS or V_DURATIONS exists
# ----------------------------------

# in: $1 view to be considered
function trips_one_hour_segs {
  local TEMPFILE=$(mktemp)
  local VIEW=$1
  
  echo "Trips in 1h segments increase left inclusive, right exclusive"
  
  for i in {0..12}; do

    local j=$(($i+1))

    if [[ "$i" != 12 ]]; then
    cat <<SQL_QUERY > $TEMPFILE
  SELECT mem, COUNT(*)
  FROM ${VIEW}
  WHERE  ${i} <= hours AND hours < ${j}
  GROUP BY mem;
SQL_QUERY
    else
  cat <<SQL_QUERY > $TEMPFILE
  SELECT mem, COUNT(*)
  FROM ${VIEW}
  WHERE hours >= ${i}
  GROUP BY mem;
SQL_QUERY
    fi

    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)
    
    echo "${i}h <= trips < ${j}h"
    echo "$RES"
  done
}
#trips_one_hour_segs $V_5MINUP_DURATIONS

# in: $1 view to be considered
function trips_5min_and_shorter {
  local TEMPFILE=$(mktemp)
  local VIEW=$1
  
  echo "Trips shorter than 5min"
  
  cat <<SQL_QUERY > $TEMPFILE
  SELECT mem, COUNT(*) FROM ${VIEW} WHERE mins <= 5 GROUP BY mem;
SQL_QUERY
  
    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)
    
    echo "Trips <= 5min"
    echo "$RES"
}
#trips_5min_and_shorter $V_5INUP_DURATIONS

# in: $1 the view 
# in: $2 what is the time segment in minutes, e.g. 120min
# in: $3 what is the step e.g. 10min, 20min
function trips_segs {
  local TEMPFILE=$(mktemp)
  local VIEW=$1
  local FINAL=$2
  local DELTA=$3
  #local END=$(($FINAL - $DELTA))
  local END=`expr $FINAL - $DELTA`
  
  echo "Trips equal or shorter than ${FINAL}min with a step ${DELTA}"
  local j=0
  for (( i=0; i<$FINAL; i = i + $DELTA)); do
  #for i in {0..$END..$DELTA}; do

    j=$(($i+$DELTA))

    if [[ "$j" != $FINAL ]]; then
    cat <<SQL_QUERY > $TEMPFILE
  SELECT mem, COUNT(*) FROM ${VIEW} WHERE  ${i} <= mins AND mins < ${j} GROUP BY mem;
SQL_QUERY
    else
  cat <<SQL_QUERY > $TEMPFILE
  SELECT mem, COUNT(*) FROM ${VIEW} WHERE ${i} <= mins AND mins <= ${j} GROUP BY mem; 
SQL_QUERY
    fi

    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)

    if [[ "$j" != $FINAL ]]; then
      echo "${i}min <= trips < ${j}min"
    else
      echo "${i}min <= trips <= ${j}min"
    fi

    echo "$RES"
  done
  cat <<SQL_QUERY > $TEMPFILE
SELECT mem, COUNT(*) FROM ${VIEW} WHERE mins > ${j} GROUP BY mem;
SQL_QUERY
  RES=$(sqlite3  $DB < $TEMPFILE)

  echo "${j}min < trips"
  echo "$RES"
}
#trips_segs $V_5INUP_DURATIONS 120 10
#trips_segs $V_5INUP_DURATIONS 120 15

# in: $1 the view 
function trips_by_month {
  local TEMPFILE=$(mktemp)
  local VIEW=$1
  
  echo "Total trips per month. Ordered by start date, mem"
  
  cat <<SQL_QUERY > $TEMPFILE
  SELECT STRFTIME('%m-%Y', start), mem, COUNT(*) 
  FRO ${VIEW} 
  GROUP BY STRFTIME('%m-%Y', start), mem
  ORDER BY STRFTIME('%m-%Y', start), mem;
SQL_QUERY

    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)
    echo "$RES"
}
#trips_by_month $V_5INUP_DURATIONS


# in: $1 the view 
# in: $2 what is the time segment in minutes, e.g. 120min
# in: $3 what is the step e.g. 10min, 20min
function trips_by_month_and_duration {
  local TEMPFILE=$(mktemp)
  local VIEW=$1
  local FINAL=$2
  local DELTA=$3
  
  echo "Trips equal or shorter than ${FINAL}min with a step ${DELTA}min"
  echo "Grouped by months and members"
  local j=0

  for (( i=0; i<$FINAL; i = i + $DELTA)); do
  #for i in {0..$END..$DELTA}; do

    j=$(($i+$DELTA))

    if [[ "$j" != $FINAL ]]; then
    cat <<SQL_QUERY > $TEMPFILE
  SELECT STRFTIME('%m-%Y', start) AS month, mem, COUNT(*) 
  FROM ${VIEW} 
  WHERE  ${i} <= mins AND mins < ${j} 
  GROUP BY month, mem;
SQL_QUERY
    else
  cat <<SQL_QUERY > $TEMPFILE
  SELECT STRFTIME('%m-%Y', start) AS month, mem, COUNT(*) 
  FROM ${VIEW} 
  WHERE ${i} <= mins AND mins <= ${j} 
  GROUP BY month, mem; 
SQL_QUERY
    fi

    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)

    if [[ "$j" != $FINAL ]]; then
      echo "${i}min <= trips < ${j}min"
    else
      echo "${i}min <= trips <= ${j}min"
    fi

    echo "$RES"
  done
  cat <<SQL_QUERY > $TEMPFILE
SELECT STRFTIME('%m-%Y', start) AS month, mem, COUNT(*)
FROM ${VIEW}
WHERE mins > ${j} 
GROUP BY month, mem;
SQL_QUERY
  RES=$(sqlite3  $DB < $TEMPFILE)

  echo ">${j}min"
  echo "$RES"
}

#trips_by_month_and_duration $V_5INUP_DURATIONS 60 15

# in: $1 how many top stations you want to consider
# in: $2 type of rider
# in: $3 which stations: start_station_name, end_station_name
function top_stations {
  local TEMPFILE=$(mktemp)
  local TOP_STATIONS=$1
  local RIDER_TYPE=$2
  local STATION=$3
  
  echo "ost ${TOP_STATIONS} popular ${STATION} for rider_type=${RIDER_TYPE}"
  echo "table|total_rows_considered"
  echo "count|${STATION}"
  
  for t in "${TABLES[@]}"; do
    # count total rows that will be considered
    cat <<SQL_QUERY1 > $TEMPFILE
SELECT COUNT(*)
FROM ${t} 
WHERE LENGTH(${STATION}) != 0 AND SUBSTR(member_casual,1,1) = '${RIDER_TYPE}';
SQL_QUERY1
    RES=$(sqlite3 $DB < $TEMPFILE) 
    echo "${t}|${RES}"
    
    cat <<SQL_QUERY2 > $TEMPFILE
SELECT ${STATION}, COUNT(*) AS num
FROM ${t}
WHERE LENGTH(${STATION}) != 0 AND SUBSTR(member_casual,1,1) = '${RIDER_TYPE}'
GROUP BY ${STATION}
ORDER BY num DESC
LIIT ${TOP_STATIONS};
SQL_QUERY2
     
    RES=$(sqlite3 $DB < $TEMPFILE) 
    echo "${RES}"

  done
}

# you can use the output to have the file for casuals or members
# use this to count how many unique station names you have
#  grep -v b_ members.txt | sort |cut -f1 -d'|' | uniq | nl
# use the below to get the stations and counts
# grep -v b_ casuals.txt | sort

#top_stations 5 m start_station_name
#top_stations 5 c start_station_name

#top_stations 3 m end_station_name
# 3 is too little for casuals for top 10 end_stations
#top_stations 4 c end_station_name


function bikes_type {
  local TEMPFILE=$(mktemp)
  
  echo "Which rideable_type do Casuals and embers prefer"
  
  for t in "${TABLES[@]}"; do
    # count total rows that will be considered
    cat <<SQL_QUERY > $TEMPFILE
SELECT COUNT(*), SUBSTR(member_casual, 1, 1), rideable_type
FROM ${t} 
GROUP BY rideable_type, SUBSTR(member_casual, 1, 1);
SQL_QUERY
    RES=$(sqlite3 $DB < $TEMPFILE) 
    echo "${t}|${RES}"
    
  done
}

#bikes_type
