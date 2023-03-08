#!/bin/bash

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/const.sh"


function min_avg_max {
  local OUTPUT_FILE=$1
  echo "Get the stations min, max and avg."
  echo "name|min(lng)|avg(lng)|max(lng)|min(lat)|avg(lat)|max(lat)"
  local TEMPFILE=$(mktemp)
  cat <<SQL_QUERY > $TEMPFILE
  SELECT name, 
    MIN(lng) AS min_lng, AVG(lng) AS avg_lng, MAX(lng) AS max_lng, 
    MIN(lat) AS min_lat, AVG(lat) AS avg_lat, MAX(lat) AS max_lat
  FROM ${V_STATIONS} WHERE LENGTH(name) != 0 GROUP BY name ORDER BY name;  
SQL_QUERY
  #cat $TEMPFILE
  $(sqlite3 $DB < $TEMPFILE > $OUTPUT_FILE)  
}

# get the stations ids, with min, max, and avg grouping by name
#min_avg_max "stations.txt"

# get stations names and their corresponding ids
# cat stations_id_names.sql | sqlite3 bikeshares.sqlite > ids_names.txt
function names_ids {
  local OUTPUT_FILE=$1
  echo "Get stations names and corresponding ids "  
  local TEMPFILE=$(mktemp)
  cat <<SQL_QUERY > $TEMPFILE
  SELECT DISTINCT name, id FROM ${V_STATIONS} WHERE LENGTH(name) != 0 ORDER BY name;  
SQL_QUERY
  #cat $TEMPFILE
  $(sqlite3 $DB < $TEMPFILE > $OUTPUT_FILE)  
}
#names_ids "names_ids.txt"

# how many stations have more than one identifiers
# select count(*), name from 
#    (select  name, id from v_stations where length(name) != 0 group by name, id) t 
# group by t.name having count(*) > 1;

# how many ids have more than one stations assigned
# select count(*), id from 
#    (select  id, name from v_stations where length(id) != 0 group by id, name) t
#       group by t.id having count(*) > 1;


# combine stations ids, names, min, avg, max (lng, lat)
# join names_ids.txt stations.txt -a 1 -t'|' > names_ids_stations.txt


# create a list of empty name stations
function list_empty_name_stations {
  echo "Create a list of empty name stations"
  local OUTPUT_FILE=$1
  local TEMPFILE=$(mktemp)
  cat <<SQL_QUERY > $TEMPFILE
  SELECT id, lng, lat FROM ${V_STATIONS} WHERE LENGTH(name) = 0 ORDER BY id;
SQL_QUERY
  $(sqlite3 $DB < $TEMPFILE > $OUTPUT_FILE)
}

#list_empty_name_stations "empty_name_stations.txt"

# computes how many stations we saved by identifying
# the lat and lng

# $1 the name of the database
# $2 which station_name
function how_many_empty_name_stations {
  local TEMPFILE=$(mktemp)
  local db1=$1
  local db2=$2

  #local start_end=$2

echo "How many empty name stations: db=$db1 - $db2"
  
for t in "${TABLES[@]}"; do

cat <<SQL_QUERY > $TEMPFILE
  SELECT COUNT(*) FROM ${t} WHERE LENGTH(start_station_name) = 0;
SQL_QUERY
  
    #cat $TEMPFILE 
    RDB1_1=$(sqlite3  $db1 < $TEMPFILE)
    RDB2_1=$(sqlite3  $db2 < $TEMPFILE)
    
cat <<SQL_QUERY > $TEMPFILE
  SELECT COUNT(*) FROM ${t} WHERE LENGTH(end_station_name) = 0;
SQL_QUERY
  
    #cat $TEMPFILE 
    RDB1_2=$(sqlite3  $db1 < $TEMPFILE)
    RDB2_2=$(sqlite3  $db1 < $TEMPFILE)


    RES=$((10#$RDB1_1+10#$RDB1_2 - 10#$RDB2_1 - 10#$RDB2_2))

    echo "$t|$RES"
done
}

#how_many_empty_name_stations bikeshares_3.sqlite $DB


# remove trips that do not have start name and end name station
function del_trips_with_empty_stations {
  local TEMPFILE=$(mktemp)
  
  echo "Remove trips that do not have start name or end name station"
  
  for t in "${TABLES[@]}"; do

cat <<SQL_QUERY > $TEMPFILE
  DELETE FROM ${t} WHERE LENGTH(start_station_name) = 0 OR LENGTH(end_station_name) = 0;
SQL_QUERY
  
    #cat $TEMPFILE 
    RES=$(sqlite3  $DB < $TEMPFILE)
    
    echo "$t|$RES"
done
}

#del_trips_with_empty_stations

# add new ids to the via importing to Excel, then import it to csv and
# as a table in sqlite
function create_stations_table {
  echo "Create a table with new ids and stations names"
  local CSV_FILENAME=$1
  local TEMPFILE=$(mktemp)

  # create a table and import the csv file to fill the table
  # skip the first row
  cat <<SQL_QUERY > $TEMPFILE
    CREATE TABLE IF NOT EXISTS ${X_STATIONS} (
    new_id INTEGER,
    id     TEXT,
    name   TEXT,
    min_lng REAL,
    avg_lng REAL,
    max_lng REAL,
    min_lat REAL,
    avg_lat REAL,
    max_lat REAL
  );
  .import --csv --skip 1 ${CSV_FILENAME} ${X_STATIONS}
SQL_QUERY

  cat $TEMPFILE
  $(sqlite3 $DB < $TEMPFILE)
}

create_stations_table "ids_stations_coord.csv"
