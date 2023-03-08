# this script lets you create a database in SQLite
# 2022-06-26

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

# get the names of the fields
field_names <- dbListFields(db, table_names[[1]][1])

exit_if_empty(table_names, paste0("ERROR: no fields in db=", DB, ". Exiting ..."))


# ---------------------------
# how many rows in each table
# ---------------------------
# @param tables - a list with one element that is the name of the 
how_many_rows <- function(tables) {
  tab_count <- length(tables[[1]])
  df <- data.frame(row.names = tables[[1]], matrix(nrow=tab_count))
  colnames(df) <-  c("total_rows_count")
  
  for(i in 1:tab_count) {
    #print(paste0("tables[", i, "]=", tables[[1]][i]))
    rs <- sqldf(paste0("SELECT COUNT(*) as total_rows FROM ", tables[[1]][i]), dbname=DB)
    #print(rs[[1]])
    #print(df)
    
    df[[1]][i] = rs[[1]]
  }
  print(df)
}

how_many_rows(table_names)


# -------------
# check nulls
# -------------
# @param tables - a list with one element
# @param fields - a character vector of column names
check_nulls <- function(tables, fields) {
  
  f_vec <- c("total_rows")
  f_vec <- append(f_vec, fields)
  
  row_count <- length(tables[[1]])
  col_count <- length(f_vec)
  
  df <- data.frame(matrix(ncol=col_count, nrow=row_count), row.names=tables[[1]])
  colnames(df) <- f_vec
  
  print(df)
  
  # now fill the rest of columns
  for(col in 1:col_count) {
    v <- c(0)
    length(v) <- row_count
    f <- f_vec[col]
    
    for (row in 1:row_count) {
      if (col == 1) {
        # we filled the first column with a different question
        sql <- paste0("SELECT COUNT(*) as ", f, " FROM ", tables[[1]][row], ";")
      } else {
        sql <- paste0("SELECT COUNT(", f,") as rows_null FROM ", tables[[1]][row], " WHERE ", f, " IS NULL;")
      }
      rs <- sqldf(sql, dbname = DB)
      v[row] <- rs[[1]]
    }
    
    df[col] <- v
  }
  
  print("-------------- Checking LENGTH=0 ------------------- ")
  print(df)
}

check_nulls(table_names, field_names)

# -------------
# check length of string fields
# -------------
# @param tables - a list with one element
# @param fields - a character vector of column names
check_length <- function(tables, fields) {

  f_vec <- c("total_rows")
  # these are fields that are real numbers - sqlite3 stores them as text
  # so we can check the length of them too
  #f_vec <- append(f_vec, fields[ ! fields %in% c("start_lat", "start_lng", "end_lat", "end_lng")])
  f_vec <- append(f_vec, fields)
  
  row_count <- length(tables[[1]])
  col_count <- length(f_vec)
  
  df <- data.frame(matrix(ncol=col_count, nrow=row_count), row.names=tables[[1]])
  colnames(df) <- f_vec
  
  #print(df)
  
  # now fill the rest of columns
  for(col in 1:col_count) {
    v <- c(0)
    length(v) <- row_count
    f <- f_vec[col]
    
    for (row in 1:row_count) {
      if (col == 1) {
        # we filled the first column with a different question
        sql <- paste0("SELECT COUNT(*) as ", f, " FROM ", tables[[1]][row], ";")
      } else {
        sql <- paste0("SELECT COUNT(", f,") as zero_length FROM ", tables[[1]][row], " WHERE length(", f, ") = 0;")
      }
      rs <- sqldf(sql, dbname = DB)
      v[row] <- rs[[1]]
    }
    
    df[col] <- v
  }
  
  print("-------------- Checking LENGTH=0 ------------------- ")
  print(df)
}

check_length(table_names, field_names)

# ------------------
# what are coordinates of the missing stations
# ------------------
check_coord <- function(tables) {
  
  df <- data.frame()

  print("-------------- Checking coord ------------------- ")

  for (t in tables) {
    print(t)
    rs <- sqldf( paste0("select start_lat, start_lng, end_lat, end_lng, count(*) as empty_start_station_name from ", t, " where length(start_station_name) = 0 group by start_lat limit 100"), dbname = DB)
    print(rs)
    rs <- sqldf( paste0("select sum(empty_start_station_name) from (select count(*) as empty_start_station_name from ",
                        t, " where length(start_station_name) = 0 group by start_lat, start_lng, end_lat, end_lng"), 
                 dbname = DB )
    print(rs)
  }
}



# -------------
# check max repeating station locations
# TODO it produces an error during execution in sqldf and dbGetQuery
# -------------
get_max_repeating_loc <- function(tables) {
  
  df <- data.frame(row.names = tables)
  print(df)
  
  for (t in tables) {
      sel <- paste0("SELECT MAX(same_loc) FROM (SELECT ride_id, start_lat, start_lng, end_lat, end_lng, COUNT(*) AS same_loc FROM ", t, " WHERE LENGTH(start_station_name)=0 GROUP BY start_lat, start_lng, end_lat, end_lng)")
      print(sel)
      #rs <- dbGetQuery(db, sel)
      rs <- sqldf( sel, dbname=DB)
      
      print(rs)
      df[t] <- rs
  }
  
  print("-------------- Max Count of the same coordinates ------------------- ")
  print(df)
}




# show info about created or existing tables
print(dbGetQuery(db, "SELECT * from sqlite_master"))

check_nulls(table_names, field_names)
check_length(table_names, field_names)
check_coord(table_names)

# don't use it; does not work
#get_max_repeating_loc(table_names)



#if (length(table_names) > 0) {
#  sqldf(paste0("pragma table_info('", table_names[i], "')"), dbname=DB)$name 
#}
#lapply(1:length(table_names), function(i) {
  #dbGetQuery(db, paste0("pragma table_info('", table_names[i], "')"))
#  sqldf(paste0("pragma table_info('", table_names[i], "')"), dbname=DB)$name 
#})
# we want to have table names automatically generated

# get the names of the csv files in the current directory
#csv_file_names <- list.files(path=".", pattern=".csv", all.files=TRUE, full.names=FALSE)
# trim names to get the date part of the csv name, eg. 202106-divvy-tripdata.csv
# and create a name "b_202106"
#table_names <- paste0("b_", substr(csv_file_names,1,regexpr("-",csv_file_names)-1))





#sqldf(paste("attach", paste("'", DB, "'", sep=""), "as new", sep = " "))
# didn't work - might be problems with the line ending
#dbWriteTable(conn=db, name="b_202205", value="202205-divvy-tripdata.csv", row.names=FALSE, header=TRUE, field.types = c(Col1 = "Text", Col2 = "Text", ))




#read.csv.sql("202205-divvy-tripdata.csv", sql = "CREATE TABLE b_202205 IF NOT EXISTS AS SELECT * FROM file", dbname = DB)

#sqldf("SELECT * from sqlite_master", dbname=DB)$tbl_name
#sqldf("pragma schema.table_info(b_202205)", dbname=DB)$name
#sqldf("pragma schema.table_info(b_202205)", dbname=DB)$type
# get info about the schema
#sqldf("pragma table_info(b_202205)", dbname=DB)
#sqldf("pragma xtable_info(b_202205)", dbname=DB)
#sqldf("SELECT sql FROM sqlite_master WHERE tbl_name='b_202205'")


# show info about created or existing tables
#dbGetQuery(db, "SELECT * from sqlite_master")

#lapply(1:length(table_names), function(i) {
  #dbGetQuery(db, paste0("pragma table_info('", table_names[i], "')"))
#  dbGetQuery(db, paste0("pragma table_xinfo('", table_names[i], "')")) 
#})


#rs <- dbSendStatement(db, "pragma xtable_info(b_202205)")
#df <- dbFetch(rs, n = 10)
#print(nrow(df))
#dbClearResult(rs)

dbDisconnect(db)
