#!/bin/bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"

function distinct_vals {
  local TEMPFILE=$(mktemp)
  
  echo "How many distinct values in member_casual field"
  
  for t in "${TABLES[@]}"; do

cat <<SQL_QUERY > $TEMPFILE
  SELECT COUNT(DISTINCT member_casual) FROM ${t};
SQL_QUERY
  
    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)
    
    echo "$t|$RES"
done
}
#distinct_vals


# how many types of member_casual
function values_in_member_casual {
  local TEMPFILE=$(mktemp)
  
  echo "What is in member_casual field and what their count is"
  
  for t in "${TABLES[@]}"; do

  # BUG possible
  # For some reason if you change the order to member_casual, COUNT(*)
  # it does not work, the member_casual is not displayed
  # SELECT member_casual, COUNT(*) FROM ${t} GROUP BY member_casual;
cat <<SQL_QUERY > $TEMPFILE
  SELECT COUNT(*), member_casual FROM ${t} GROUP BY member_casual;
SQL_QUERY
  
    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)
    #echo "$t"
    echo "$t|$RES"
done
}
#values_in_member_casual

# how many types of member_casual
function is_null {
  local TEMPFILE=$(mktemp)
  
  echo "Any null or zero-length values for records with member_casual field"
  
  for t in "${TABLES[@]}"; do

  # BUG possible
  # For some reason if you change the order to member_casual, COUNT(*)
  # it does not work, the member_casual is not displayed
  # SELECT member_casual, COUNT(*) FROM ${t} GROUP BY member_casual;
cat <<SQL_QUERY > $TEMPFILE
  SELECT * FROM ${t} WHERE member_casual IS NULL OR LENGTH(member_casual) = 0;
SQL_QUERY
  
    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)
    echo "$t|$RES"
done
}
is_null