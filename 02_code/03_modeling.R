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

# Modeling Setup ----------------------------------------------------------

set.seed(123)
# create splits for 5-fold CV resampling
cv_splits <- vfold_cv(data_train, 
                      v = 5)

# custom metric penalizing false negatives
classification_cost_penalized <- function(
  data,
  truth,
  class_prob,
  na_rm = TRUE
) {
  
  # cost matrix penalizing false negatives
  cost_matrix <- tribble(
    ~truth, ~estimate, ~cost,
    "fire", "none",  2,
    "none", "fire",  1
  )
  
  classification_cost(
    data = data,
    truth = !! rlang::enquo(truth),
    # supply the function with the class probabilities
    !! rlang::enquo(class_prob), 
    # supply the function with the cost matrix
    costs = cost_matrix,
    na_rm = na_rm
  )
}

# formalize new metric
classification_cost_penalized <- new_prob_metric(classification_cost_penalized, "minimize")

# specify metrics
metrics <- metric_set(classification_cost_penalized, f_meas, 
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