library(tidyverse)

# load data ---------------------------------------------------------------
data <- read_rds("01_data/data_final.rds")

# data exploration --------------------------------------------------------
str(data)

# data preparation --------------------------------------------------------

dummies <- c("river", "lake", "recreational_routes", "campground",
             "state_park", "picnic", "powerline", "road")

distance <- c("dist_lake", "dist_power", "dist_river", "dis_road")

# TODO
# center - subtract avg value - mean of 0
# scale  - divide by SD - SD of 1
# skewness resolve - roughly symmetric distribution - ln or box-cox
# data reduction with PCA? - for GLM (resolve skewness and center+scale first)
# test for variance in predictors -> % unique values < 10%? 
## ratio of most frequent to 2nd freq value ~20?
## cause to drop variable
# test for collinearity
## correlation matrix
## pair-wise removal of highly correlated predictors
