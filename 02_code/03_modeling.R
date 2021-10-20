library(tidyverse)
library(tidymodels)
# require("devtools")
# install_github("tidymodels/themis")
library(themis)

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

# train-/test split
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

data_train <- data %>% 
  filter(year <= 2016)

data_test <- data %>% 
  filter(year > 2016)

# specify model
glm_model <- logistic_reg() %>% 
  set_engine("glm") %>% 
  set_mode("classification")

# GLM naive ---------------------------------------------------------------
# specify recipe
glm_naive_recipe <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID")

# bundle model and recipe to workflow
glm_naive_workflow <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_naive_recipe)

# fit model with train data
glm_naive_fit <- glm_naive_workflow %>% 
  fit(data = data_train)

# inspect coefficients
glm_naive_fit %>% 
  extract_fit_parsnip() %>% 
  tidy()

# predict with test data
glm_naive_pred <- predict(glm_naive_fit, 
                          new_data = data_test)

# number of positive predictions
glm_naive_pred %>% 
  pull(.pred_class) %>% 
  table()

# add predicted values and probabilities to data set
glm_naive_aug <- 
  augment(glm_naive_fit, data_test)

# inspect
glm_naive_aug %>%
  select(fire, .pred_class, .pred_TRUE, .pred_FALSE, 
         id, year, season)

# plot ROC curve
glm_naive_aug %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# compute ROC AUC
glm_naive_aug %>% 
  roc_auc(truth = fire, .pred_FALSE)

# confusion matrix
glm_naive_confmat <- glm_naive_aug %>% 
  conf_mat(truth = fire, estimate = .pred_class)
glm_naive_confmat

# additional metrics 
summary(glm_naive_confmat, 
        event_level = 'second')

# The model shows the typical symptoms of a heavily imbalanced data set
# very high accuracy, but the confusion matrix shows that the model
# is heavily overfit to negative events --> upsampling needed
# multicollinearity also seems to be a problem --> remove highly correlated features

# GLM upsampled & resampled -----------------------------------------------
  
# preprocessing recipe
# glm_recipe <-  recipe(fire ~ ., data = data_train) %>% 
#   # remove id from predictors
#   update_role(id, new_role = "ID") %>% 
#   # drop highly correlated features
#   step_rm(lake, river, powerline, road,
#           recreational_routes, starts_with('perc_yes')) %>%
#   # upsampling with ROSE
#   step_rose(fire, 
#             # skip for test set
#             skip = TRUE) %>%
#   # turn all categorical features into dummy variables
#   step_dummy(all_nominal_predictors()) %>%
#   # remove 0-variance features
#   step_zv(all_predictors()) %>%
#   # remove highly-correlated features
#   step_corr(all_predictors(),
#             threshold = .9)

glm_recipe <-  recipe(fire ~ ., data = data_train) %>% 
  # remove id from predictors
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>%
  # turn all categorical features into dummy variables
  step_dummy(all_nominal_predictors()) %>%
  # upsampling with SMOTE
  step_smote(fire, 
            # skip for test set
            skip = TRUE) %>%
  # power transformation for skewed distance features
  step_sqrt(starts_with('dist_')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_predictors(),
            threshold = .9)

# create splits for 10-fold CV resampling
cv_splits <- vfold_cv(data_train, 
                      v = 10)

# bundle model and recipe to workflow
glm_workflow <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_recipe)

# specify metrics
metrics <- metric_set(roc_auc, f_meas, sens, spec, accuracy)

# fit model
start <- Sys.time()
glm_fit <- glm_workflow %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control_resamples(
                  verbose = TRUE,
                  save_pred = TRUE,
                  event_level = "second")
                )
end <- Sys.time()
end-start

# write_rds(glm_fit, "03_outputs/glm_fit.rds")
# glm_fit <- read_rds("03_outputs/glm_fit.rds")

# metrics of resampled fit
collect_metrics(glm_fit)

# within-fold predictions
glm_preds <- collect_predictions(glm_fit, 
                    summarize = TRUE)

# plot ROC curve
glm_preds %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# confusion matrix
glm_confmat <- glm_preds %>% 
  conf_mat(truth = fire, estimate = .pred_class)
glm_confmat

# additional metrics 
summary(glm_confmat, 
        event_level = 'second')

# GLMnet ------------------------------------------------------------------
# define model
elanet_model <- 
  logistic_reg(penalty = tune(), 
               mixture = tune()) %>% 
  set_engine("glmnet") %>% 
  set_mode("classification")

# create recipe
elanet_recipe <-  recipe(fire ~ ., data = data_train) %>% 
  # remove id from predictors
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>%
  # turn all categorical features into dummy variables
  step_dummy(all_nominal_predictors()) %>%
  # upsampling with SMOTE
  step_smote(fire, 
             # skip for test set
             skip = TRUE) %>%
  # power transformation for skewed distance features
  step_sqrt(starts_with('dist_')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_predictors(),
            threshold = .9) %>% 
  # normalize all features
  step_normalize(all_numeric_predictors())

# combine model specification & recipe to workflow
elanet_wf <- workflow() %>% 
  add_model(elanet_model) %>% 
  add_recipe(elanet_recipe)

# set up tuning grid
elanet_grid <- grid_regular(penalty(),
                            mixture(),
                            levels = 5)

# tune with 10-fold CV
elanet_tune <- elanet_wf %>% 
  tune_grid(
    resamples = cv_splits,
    grid = elanet_grid,
    control = control_grid(save_pred = TRUE, 
                           verbose = TRUE, 
                           event_level = 'second')
  )

# write_rds(elanet_tune, "03_outputs/elanet_tune.rds")
# elanet_tune <- read_rds("03_outputs/elanet_tune.rds")


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
