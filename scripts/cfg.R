# 2022-06-28
# config file with constants

# location where the .csv files are
#PATH <- "Z:/tmp/bs"
#PATH <- "D:/2022-06-07-capstone"
PATH <- "D:/tmp/bs"
#PATH <- "E:/tmp/bs"

setwd(PATH)
# name of the database
DB <- "bikeshares.sqlite"

# names of internal tables created for making computations easier
# x_totrows - list of databases as id and the total number of rows
EXTRA_TABLES <- c("x_totrows", "v_stations")

