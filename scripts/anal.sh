#!/bin/bash

# 2022-07-31
# this is a continuation of the analysis.sh
# because analysis.sh stopped working, I 
# decided to continue it in the new file

# run the script with tables names and columns names
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

# broken by days of the week
# in: $1 - view
function days_of_week {
  local TEMPFILE=$(mktemp)
  local VIEW=$1

  echo "Which days of the week do riders prefer?"
  echo "0 - Sunday, 1-Monday, ..., 6-Saturday"
  
  # Sunday 0, weekdays 0-6
  cat <<SQL_QUERY > $TEMPFILE
SELECT STRFTIME('%m-%Y', start) AS month, 
       STRFTIME('%w', start) AS weekday, 
       mem,
       COUNT(*)
FROM ${VIEW}
GROUP BY month,
         weekday, 
         mem;
SQL_QUERY
  
  RES=$(sqlite3 $DB < $TEMPFILE) 
  echo "${RES}"    

}

#days_of_week $V_5MINUP_DURATIONS

# broken by days of the week
# in: $1 - view
function time_of_day {
  local TEMPFILE=$(mktemp)
  local VIEW=$1
  local START_HOUR=$2
  local END_HOUR=$3

  echo "Trips that start in  [${START_HOUR};${END_HOUR})"
    
  cat <<SQL_QUERY > $TEMPFILE
SELECT STRFTIME('%m-%Y', start) AS month,  
       mem,
       COUNT(*)
FROM ${VIEW}
WHERE CAST(STRFTIME('%H', start) AS INT)  >= ${START_HOUR} AND 
      CAST(STRFTIME('%H', start) AS INT)  < ${END_HOUR}
GROUP BY month,         
         mem;
SQL_QUERY
  
  RES=$(sqlite3 $DB < $TEMPFILE) 
  echo "${RES}"    
}

# night, morning, afternoon, evening, night
time_of_day $V_5MINUP_DURATIONS 0 5
time_of_day $V_5MINUP_DURATIONS 5 12
time_of_day $V_5MINUP_DURATIONS 12 17
time_of_day $V_5MINUP_DURATIONS 17 24
