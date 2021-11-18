library(tidyverse)
library(tidymodels)
library(stacks)
library(themis)

glm_tune <- read_rds("03_outputs/models/GLM_tune_randomsampled.rds")
rf_tune <- read_rds("03_outputs/models/RF_tune_randomsampled.rds")
xgb_tune <- read_rds("03_outputs/models/XGB_tune_randomsampled.rds")

# create stack
model_stack <- stacks() %>%
  # add candidate models
  add_candidates(glm_tune) %>%
  add_candidates(rf_tune) %>%
  add_candidates(xgb_tune)
model_stack

# fit stack
model_stack_fit <-
  model_stack %>%
  # determine optimal candidate combination
  blend_predictions() %>% 
  # fit accordingly 
  fit_members()

# write to disk
write_rds(model_stack_fit, "03_outputs/models/stack.rds")
# read from disk
model_stack_fit <- read_rds("03_outputs/models/stack.rds")

# save predictions
stack_preds <- model_stack_fit %>% 
  # predict with stack
  predict(new_data = data_test) %>% 
  # bind predictions to testing data
  bind_cols(data_test)

stack_preds %>% 
  conf_mat(truth = fire, estimate = .pred_class)
