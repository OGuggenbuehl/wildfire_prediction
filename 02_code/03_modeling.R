library(tidyverse)
library(tidymodels)
# require("devtools")
# install_github("tidymodels/themis")
library(themis)
library(doParallel)
options(tidymodels.dark = TRUE)

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
  mutate_if(is.logical, as.numeric) %>% 
  mutate(fire = recode(fire, 
                       'TRUE' = 'fire', 
                       'FALSE' = 'none'),
         fire = fct_relevel(fire, c('fire', 'none')))

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
metrics <- metric_set(mn_log_loss, f_meas, 
                      precision, recall,
                      sensitivity, specificity,
                      accuracy, roc_auc)
# fit control
control <- control_resamples(
  verbose = TRUE,
  save_pred = TRUE,
  # event_level = "second", 
  allow_par = TRUE, 
  parallel_over = 'resamples')

# set up parallel-processing backend
all_cores <- parallel::detectCores(logical = FALSE)
cl <- makePSOCKcluster(all_cores)

# GLM ---------------------------------------------------------------------
# upsampled & resampled
source("02_code/03.1_GLM_res.R")
# tuned elastic net
source("02_code/03.2_GLM_tune.R")

# Random Forest -----------------------------------------------------------
# upsampled & resampled
source("02_code/03.3_RF_res.R")
# tuned
source("02_code/03.4_RF_tune.R")

# XGB ---------------------------------------------------------------------
# upsampled & resampled
source("02_code/03.5_xgb_res.R")
# tune
source("02_code/03.6_xgb_tune.R")

# Stacking ----------------------------------------------------------------
source("02_code/03.7_stacks.R")