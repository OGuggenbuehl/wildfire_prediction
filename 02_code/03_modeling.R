library(tidyverse)
library(tidymodels)
# require("devtools")
# install_github("tidymodels/themis")
library(themis)
library(doParallel)

# load data ---------------------------------------------------------------

data <- read_rds("01_data/data_seasonal.rds") %>% 
  # turn booleans into factors for modeling
  mutate(fire = as_factor(fire)) %>% 
  # drop features
  select(-c(perc_republicans,
            county_persons_per_household,
            temp_min_avg,
            temp_max_avg,
            county_unemployment, 
            county_unemployment_rate)) %>% 
  mutate_if(is.logical, as.numeric)

# Randomized train/test split ---------------------------------------------
# set.seed(123)
# splits <- initial_split(data,
#                         # set split proportion
#                         prop = 0.7,
#                         # stratify by highly imbalanced response
#                         strata = fire)
# 
# # create train set
# data_train <- training(splits)
# # create test set
# data_test  <- testing(splits)
# # create validation set
# data_valid <- validation_split(data_train, 
#                                strata = fire, 
#                                prop = 0.7)


# time-based train/test split ---------------------------------------------
n_train <- data %>% 
  mutate(train = if_else(year <= 2016, TRUE, FALSE)) %>% 
  pull(train) %>% 
  sum()

prop <- n_train/ nrow(data)

t_split <- initial_time_split(data %>% arrange(year), 
                              prop = prop)

data_train <- training(t_split)
data_test <- testing(t_split)

# Modeling Setup ----------------------------------------------------------

set.seed(123)
# create splits for 5-fold CV resampling
cv_splits <- vfold_cv(data_train, 
                      v = 5)

# specify metrics
metrics <- metric_set(roc_auc, accuracy, sens, spec, 
                      f_meas, precision, recall)

# set up parallel-processing backend
all_cores <- parallel::detectCores(logical = FALSE)
cl <- makePSOCKcluster(all_cores)

# GLM naive ---------------------------------------------------------------
source("02_code/03.1_GLM_naive.R")

# GLM upsampled & resampled -----------------------------------------------
source("02_code/03.2_GLM_up_resampled.R")

# GLMnet ------------------------------------------------------------------
source("02_code/03.3_GLMnet.R")

# SVM ---------------------------------------------------------------------

# Random Forest -----------------------------------------------------------
source("02_code/03.5_RF_naive.R")

# XGB ---------------------------------------------------------------------


# Stacking ----------------------------------------------------------------
