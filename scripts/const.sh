#!/bin/bash

# all tables with bikesharing data
TABLES=("b_202106" "b_202107" "b_202108" "b_202109" "b_202110" "b_202111" "b_202112" "b_202201" "b_202202" "b_202203" "b_202204" "b_202205")

# the additional table with extra rows
X_TOTROWS="x_totrows"

# extra table that contains new ids, current ids, min, avg, max, lng and lat
X_STATIONS="x_stations"

# view created to create a table with station ids, lat, lng, etc
V_STATIONS="v_stations"

# view for durations
V_DURATIONS="v_durations"

# view for durations of more than 5min
V_5MINUP_DURATIONS="v_5min_up_durations"


# all fields
FIELDS=("ride_id" "rideable_type" "started_at" "ended_at" "start_station_name" "start_station_id" "end_station_name" "end_station_id" "start_lat" "start_lng" "end_lat" "end_lng" "member_casual")

# only text fields
TXTFIELDS=("ride_id" "rideable_type" "started_at" "ended_at" "start_station_name" "start_station_id" "end_station_name" "end_station_id" "member_casual")

# the name of the database for bikesharing data
DB="bikeshares.sqlite"