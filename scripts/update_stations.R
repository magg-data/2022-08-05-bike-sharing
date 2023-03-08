# update the stations ids

# TODO repetition of stations.R

# run the config script with constants
if (!exists("DB", mode = "character")) {
  source("cfg.R")
}

library(sqldf) # needs 
library(DBI)

db <- dbConnect(SQLite(), dbname=DB)
# remember table names; a list with one element which is a sequence of tables'
# names' so to get to a list of names you have to use table_names[[1]] and 
# then you can get the table names for particular tables
all_table_names <- sqldf("SELECT tbl_name from sqlite_master", dbname=DB)
# the tables with bikeshare data b_* remove any others
tmp_list <- all_table_names[[1]]
table_names <- list( tmp_list[! (tmp_list %in% EXTRA_TABLES)]  )

exit_if_empty <- function(v, err_msg) {
  if (length(v) == 0) {
    #sprintf(err_msg)
    dbDisconnect(db)
    stop(err_msg)
  }
}

exit_if_empty(table_names, paste0("ERROR: no tables, no column names in db=", DB, ". Exiting ..."))


exit_if_empty(table_names, paste0("ERROR: no fields in db=", DB, ". Exiting ..."))


# @in: tables - tables in a db
# @in: lng - the longitute identifying the station
# @in: lat - the latitude identifying the station
# @in: station_name - the name of the station
update_rows <- function(tables, lng, lat, station_name) {
  for(i in 1:length(tables[[1]])) {
    #print(paste0("tables[", i, "]=", tables[[1]][i]))
    sqldf(paste0("UPDATE ", tables[[1]][i], " SET start_station_name = '", station_name, 
                 "' WHERE LENGTH(start_station_name) = 0 AND start_lng = ", lng, 
                 " AND start_lat = ", lat, ";"), dbname=DB)
    sqldf(paste0("UPDATE ", tables[[1]][i], " SET end_station_name = '", station_name, 
                 "' WHERE LENGTH(end_station_name) = 0 AND end_lng = ", lng, 
                 " AND end_lat = ", lat, ";"), dbname=DB)
  }
}

# @in: tables - tables in a db
# @in: stations_ids_csv - the file name with csv data regarding stations ids
# @in: empty_stations_csv - the file name with csv data regarding empty stations
update_stations <- function(tables, stations_ids_csv, empty_stations_csv) {
  
  # read the csv files to create 
  stations_df <- read.csv(stations_ids_csv)
  colnames(stations_df) <- c("name", "org_id", "min_lng", "avg_lng", "max_lng", "min_lat", "avg_lat", "max_lat")
  empty_stations_df <- read.csv(empty_stations_csv)
  colnames(empty_stations_df) <- c("lng", "lat")
  
  for (i in 1:nrow(empty_stations_df)) {
    e_lng <- empty_stations_df[["lng"]][i]
    e_lat <- empty_stations_df[["lat"]][i]
    
    # get the name of the stations
    # how many stations identified
    count <- 0
    name <- ""
    for( j in 1:nrow(stations_df)) {
      if (e_lng >= stations_df[["min_lng"]][j] && e_lng <= stations_df[["max_lng"]][j] && 
          e_lat >= stations_df[["min_lat"]][j] && e_lat <= stations_df[["max_lat"]][j]) {
        count <- count + 1
        name <- stations_df[["name"]][j]
      }
    }
    
    if (count == 1) {
      #print(sprintf("%d, %f, %f, %s", i, e_lng, e_lat, name))
      print(paste(i, e_lng, e_lat, name, sep=","))
      update_rows(tables, e_lng, e_lat, name)
    } 
  }
}

update_stations(table_names, "stations_ids.csv", "empty_stations.csv")

dbDisconnect(db) 
