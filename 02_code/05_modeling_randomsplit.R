library(tidyverse)
library(tidymodels)
# require("devtools")
# install_github("tidymodels/themis")
library(themis)
library(vip)
library(parallel)
library(doFuture)
library(writexl)
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

r_split <- initial_split(data, 
                         prop = prop, 
                         strata = fire)

data_train <- training(r_split)
data_test <- testing(r_split)

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

# Fit models --------------------------------------------------------------

# GLM
source("02_code/05.1_GLM_tune.R", echo = TRUE)
# RF
source("02_code/05.2_RF_tune.R", echo = TRUE)
# XGB
source("02_code/05.3_XGB_tune.R", echo = TRUE)

# Evaluate models ---------------------------------------------------------

# GLM
source("02_code/05.4_GLM_eval.R", echo = TRUE)
# RF
source("02_code/05.5_RF_eval.R", echo = TRUE)
# XGB
source("02_code/05.6_XGB_eval.R", echo = TRUE)

# create table for comparing metrics
model_comp_random <- glm_tuned_down_metrics %>% 
  bind_rows(rf_tuned_down_metrics) %>%
  bind_rows(xgb_tuned_down_metrics) %>% 
  select(.metric, .estimate, model) %>% 
  arrange(model, .metric) %>% 
  mutate(.estimate = round(.estimate, digits = 3)) %>% 
  pivot_wider(names_from = model, values_from = .estimate)

# write to disk
write_rds(model_comp_random, "03_outputs/tables/model_comp_rsplit.rds")
# read from disk
model_comp_random <- read_rds("03_outputs/tables/model_comp_rsplit.rds")

# write to disk for .docx import
write.table(model_comp_random, file = "03_outputs/tables/model_comp_rsplit.txt", 
            sep = ",", quote = FALSE, row.names = FALSE)

# Ensemble Stack ----------------------------------------------------------

source("02_code/05.7_stacking.R", echo = TRUE)
