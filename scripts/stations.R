# creates a station name, id, lat, lng 


# read the csv files to create 
stations_df <- read.csv("stations_ids.csv")
colnames(stations_df) <- c("name", "org_id", "min_lng", "avg_lng", "max_lng", "min_lat", "avg_lat", "max_lat")
empty_stations_df <- read.csv("empty_stations.csv")
colnames(empty_stations_df) <- c("lng", "lat")

count_single_stations <- 0

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
    count_single_stations <- count_single_stations + 1
  } 
  #else {
  #  print(paste(i, count, sep=","))
  #}
}

print(paste("single stations count: ", count_single_stations))
