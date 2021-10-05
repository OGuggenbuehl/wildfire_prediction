library(tidyverse)

# load data ---------------------------------------------------------------
data <- read_rds("01_data/data_final.rds")

# data exploration --------------------------------------------------------
str(data)

# data preparation --------------------------------------------------------

dummies <- c("river", "lake", "recreational_routes", "campground",
             "state_park", "picnic", "powerline", "road")

distance <- c("dist_lake", "dist_power", "dist_river", "dis_road")
