library(tidyverse)
library(tidymodels)

# load data ---------------------------------------------------------------

data <- read_rds("01_data/data_final.rds") %>% 
  # turn booleans into factors for modeling
  mutate(fire = as_factor(fire)) %>% 
  # drop features
  select(-c(perc_republicans,
            county_persons_per_household,
            temp_min_avg,
            temp_max_avg))

# train-/test split
set.seed(123)
splits <- initial_split(data,
                        # set split proportion
                        prop = 0.7,
                        # stratify by highly imbalanced response
                        strata = fire)

# create train set
data_train <- training(splits)
# create test set
data_test  <- testing(splits)
# create validation set
data_valid <- validation_split(data_train, 
                               strata = fire, 
                               prop = 0.7)

# GLM ---------------------------------------------------------------------
# specify model
glm_model <- logistic_reg() %>% 
  set_engine("glm") %>% 
  set_mode("classification")

# preprocessing recipe
glm_recipe <- recipe(fire ~ ., data = data) %>% 
  update_role(id, season, new_role = "ID") %>% 
  step_dummy(all_nominal_predictors()) %>% 
  # step_mutate(fire = fire %>% as.numeric %>% as_factor) %>%
  step_corr(all_numeric_predictors(), threshold = .5) %>% 
  step_zv(all_predictors()) %>% 
  step_normalize(all_numeric_predictors())

# bundle model and recipe to workflow
glm_workflow <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_recipe)

# fit model
start <- Sys.time()
glm_fit <- glm_workflow %>% 
  fit(data = data_train)
end <- Sys.time()
end-start

# inspect coefficients
glm_fit %>% 
  extract_fit_parsnip() %>% 
  tidy() 

# predict with test data
glm_preds <- predict(glm_fit, data_test)

# number of positive predictions
glm_preds %>% 
  pull(.pred_class) %>% 
  table()

# add predicted values and probabilities to data set
glm_aug <- 
  augment(glm_fit, data_test)

# inspect
glm_aug %>%
  select(fire, .pred_class, .pred_TRUE, .pred_FALSE, 
         id, year, month)

# plot ROC curve
glm_aug %>% 
  roc_curve(truth = fire, .pred_TRUE) %>% 
  autoplot()

# compute ROC AUC
glm_aug %>% 
  roc_auc(truth = fire, .pred_TRUE)

# confusion matrix
glm_confmat <- glm_aug %>% 
  conf_mat(truth = fire, estimate = .pred_class)
glm_confmat

# additional metrics 
summary(glm_confmat, 
        event_level = 'second')
# SVM ---------------------------------------------------------------------


# Random Forest -----------------------------------------------------------
# specify model
rf_model <- rand_forest(mtry = 3, 
                         min_n = 3, 
                         trees = 1000) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

# preprocessing recipe
rf_recipe <- recipe(fire ~ ., data = data) %>% 
  update_role(id, season, new_role = "ID")

# bundle model and recipe to workflow
rf_workflow <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe)

# fit model
start <- Sys.time()
rf_fit <- rf_workflow %>% 
  fit(data = data_train)
end <- Sys.time()
end-start

# predict with test data
rf_preds <- predict(rf_fit, data_test)

# number of positive predictions
rf_preds %>% 
  pull(.pred_class) %>% 
  table()

# add predicted values and probabilities to data set
rf_aug <- 
  augment(rf_fit, data_test)

# inspect
rf_aug %>%
  select(fire, .pred_class, .pred_TRUE, .pred_FALSE, 
         id, year, month)

# plot ROC curve
rf_aug %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# compute ROC AUC
rf_aug %>% 
  roc_auc(truth = fire, .pred_FALSE)

# confusion matrix
rf_confmat <- rf_aug %>% 
  conf_mat(truth = fire, estimate = .pred_class)
rf_confmat

# additional metrics 
summary(rf_confmat, 
        event_level = 'second')

# XGB ---------------------------------------------------------------------


# Stacking ----------------------------------------------------------------


