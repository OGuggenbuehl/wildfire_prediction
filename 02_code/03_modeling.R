library(tidyverse)
library(tidymodels)
# require("devtools")
# install_github("tidymodels/themis")
library(themis)
library(parallel)
library(doFuture)
options(tidymodels.dark = TRUE)

# load data ---------------------------------------------------------------

data <- read_rds("01_data/data_seasonal.rds") %>% 
  # turn booleans into factors for modeling
  mutate(fire = as_factor(fire)) %>% 
  # drop features
  select(-c(perc_republicans,
            DPA_agency,
            county_persons_per_household,
            temp_min_avg,
            temp_max_avg, 
            county_unemployment_rate,
            county_unemployment)) %>% 
  mutate_if(is.logical, as.numeric) %>% 
  mutate(fire = recode(fire, 
                       'TRUE' = 'fire', 
                       'FALSE' = 'none'),
         fire = fct_relevel(fire, c('fire', 'none')))

# time-based train/test split ---------------------------------------------
n_train <- data %>% 
  mutate(train = if_else(year <= 2016, TRUE, FALSE)) %>% 
  pull(train) %>% 
  sum()

prop <- n_train/nrow(data)

t_split <- initial_time_split(data %>% arrange(year), 
                              prop = prop)

data_train <- training(t_split)
data_test <- testing(t_split)

# write to disk
write_rds(data_train, "01_data/data_train.rds")
write_rds(data_test, "01_data/data_test.rds")

# Modeling Setup ----------------------------------------------------------

set.seed(123)
# create splits for 5-fold CV resampling
cv_splits <- vfold_cv(data_train, 
                      v = 5)

source("02_code/custom_cost_matrix.R")

# specify metrics
metrics <- metric_set(classification_cost_penalized,
                      f_meas, precision, recall,
                      sensitivity, specificity,
                      accuracy, roc_auc)

# fit control
control <- control_resamples(
  # verbose for convenience 
  verbose = TRUE,
  # needed for stacking
  save_pred = TRUE,
  # needed for stacking
  save_workflow = TRUE,
  # needed for parallelization
  allow_par = TRUE, 
  parallel_over = 'resamples')

# setup up parallel-processing backend
registerDoFuture()
all_cores <- detectCores(logical = FALSE)

# GLM ---------------------------------------------------------------------
# naive estimation
source("02_code/03.1_GLM_naive.R", echo = TRUE)
# resampled
source("02_code/03.2_GLM_res.R", echo = TRUE)
# tune elastic net
source("02_code/03.3_GLM_tune.R", echo = TRUE)
# final fit
source("02_code/03.4_GLM_final.R", echo = TRUE)

# Random Forest -----------------------------------------------------------
# naive estimation
source("02_code/03.5_RF_naive.R", echo = TRUE)
# resampled
source("02_code/03.6_RF_res.R", echo = TRUE)
# tuned
source("02_code/03.7_RF_tune.R", echo = TRUE)
# final fit
source("02_code/03.8_RF_final.R", echo = TRUE)

# XGB ---------------------------------------------------------------------
# naive
source("02_code/03.9_XGB_naive.R", echo = TRUE)
# resampled
source("02_code/03.10_XGB_res.R", echo = TRUE)
# tune
source("02_code/03.11_XGB_tune.R", echo = TRUE)
# final fit
source("02_code/03.12_XGB_final.R", echo = TRUE)

# Stacking ----------------------------------------------------------------
source("02_code/03.13_stacking.R", echo = TRUE)