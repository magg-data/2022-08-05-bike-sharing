# this script lets you create a database in SQLite
# 2022-06-26

# run the config script with constants
if (!exists("DB", mode = "character")) {
  source("cfg.R")
}



library(sqldf) #TODO what is the difference between DBI and sqldf - which is better

# we want to have table names automatically generated

# get the names of the csv files in the current directory
csv_file_names <- list.files(path=".", pattern=".csv", all.files=TRUE, full.names=FALSE)
# trim names to get the date part of the csv name, eg. 202106-divvy-tripdata.csv
# and create a name "b_202106"
table_names <- paste0("b_", substr(csv_file_names,1,regexpr("-",csv_file_names)-1))

library(DBI)

# create a connection to bikedatabase
db <- dbConnect(SQLite(), dbname=DB)
#sqldf(paste("attach", paste("'", DB, "'", sep=""), "as new", sep = " "))
# didn't work - might be problems with the line ending
#dbWriteTable(conn=db, name="b_202205", value="202205-divvy-tripdata.csv", row.names=FALSE, header=TRUE, field.types = c(Col1 = "Text", Col2 = "Text", ))

# create tables or ignore if they exist

for  (i in 1:length(csv_file_names)) {
  if (!dbExistsTable(db, table_names[i])) {
    # names of fields figured out earlier by skipping field.types
    # it guesses wrongly some types in some situations like for 2021-06, 
    # start_station_name is INTEGER so have to specify the fields
    dbWriteTable(conn=db, name=table_names[i], value=csv_file_names[i], 
                 row.names=FALSE, header=TRUE, 
      field.types = c(ride_id = "TEXT", rideable_type = "TEXT", started_at = "TEXT", 
                      ended_at = "TEXT", start_station_name = "TEXT", 
                      start_station_id = "TEXT", end_station_name = "TEXT", end_station_id = "TEXT", 
                      start_lat = "REAL", start_lng = "REAL", end_lat = "REAL", end_lng = "REAL", member_casual = "TEXT"))
    sprintf("INFO: %s table created ...", table_names[i])
    
  } else {
    sprintf("INFO: %s table exists. CREATE skipped ...", table_names[i])
  }
}

#read.csv.sql("202205-divvy-tripdata.csv", sql = "CREATE TABLE b_202205 IF NOT EXISTS AS SELECT * FROM file", dbname = DB)

#sqldf("SELECT * from sqlite_master", dbname=DB)$tbl_name
#sqldf("pragma schema.table_info(b_202205)", dbname=DB)$name
#sqldf("pragma schema.table_info(b_202205)", dbname=DB)$type
# get info about the schema
#sqldf("pragma table_info(b_202205)", dbname=DB)
#sqldf("pragma xtable_info(b_202205)", dbname=DB)
#sqldf("SELECT sql FROM sqlite_master WHERE tbl_name='b_202205'")


# show info about created or existing tables
print(dbGetQuery(db, "SELECT * from sqlite_master"))

lapply(1:length(table_names), function(i) {
  #dbGetQuery(db, paste0("pragma table_info('", table_names[i], "')"))
  print(dbGetQuery(db, paste0("pragma table_xinfo('", table_names[i], "')")) )
})


#rs <- dbSendStatement(db, "pragma xtable_info(b_202205)")
#df <- dbFetch(rs, n = 10)
#print(nrow(df))
#dbClearResult(rs)

dbDisconnect(db)
