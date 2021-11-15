library(glmnet)

# specify model
elanet_model <- 
  # enable tuning of hyperparameters
  logistic_reg(penalty = tune(), 
               mixture = tune()) %>% 
  set_engine("glmnet") %>% 
  set_mode("classification")

# Upsampling using SMOTE --------------------------------------------------

# preprocessing recipe (upsampling)
elanet_recipe_up <-  recipe(fire ~ ., data = data_train) %>% 
  # remove id from predictors
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>%
  # power transformation for skewed distance features
  step_sqrt(starts_with('dist_')) %>% 
  # normalize all features
  step_normalize(all_numeric_predictors()) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .75) %>% 
  # remove ID for train set due to bugged step_nearmiss and step_tomek
  step_rm(id, skip = TRUE) %>%
  # turn all categorical features into dummy variables
  step_dummy(all_nominal_predictors()) %>%
  # upsampling with SMOTE
  step_smote(fire, 
             # skip for test set
             skip = TRUE) %>% 
  # remove TOMEK-links for better class boundaries
  step_tomek(fire, 
             # skip for test set
             skip = TRUE)

# combine model specification & recipe to workflow
elanet_wf_up <- workflow() %>% 
  add_model(elanet_model) %>% 
  add_recipe(elanet_recipe_up)

# set up tuning grid
elanet_grid <- grid_regular(penalty(),
                            mixture(),
                            levels = 5)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# resample with 5-fold CV
start <- Sys.time()
elanet_tune_up <- elanet_wf_up %>% 
  tune_grid(
    resamples = cv_splits,
    grid = elanet_grid,
    metrics = metrics, 
    control = control
    )
end <- Sys.time()
end-start

# write to disk
# write_rds(elanet_tune_up, "03_outputs/GLM_tune_upsampled.rds")
# read from disk
elanet_tune_up <- read_rds("03_outputs/GLM_tune_upsampled.rds")

# show metrics
collect_metrics(elanet_tune_up)

# select best tuning specification
best_elanet_up <- select_best(elanet_tune_up, "classification_cost_penalized")

# finalize workflow with best tuning parameters
final_elanet_wf_up <- elanet_wf_up %>% 
  finalize_workflow(best_elanet_up)

# fit final elanet model
final_elanet_fit_up <- final_elanet_wf_up %>%
  last_fit(split = t_split, 
           metrics = metrics)

# write to disk
# write_rds(final_elanet_fit_up, "03_outputs/GLM_final_upsampled.rds")
# read from disk
final_elanet_fit_up <- read_rds("03_outputs/GLM_final_upsampled.rds")

# shut down workers
stopCluster(cl = cl)

# metrics
final_elanet_fit_up %>%
  collect_metrics()

# ROC curve
final_elanet_fit_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# Confusion Matrix
final_elanet_fit_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampling using NearMiss 1 -------------------------------------------

# preprocessing recipe (downsampling)
elanet_recipe_down <- recipe(fire ~ ., data = data_train) %>% 
  # remove id from predictors
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>%
  # power transformation for skewed distance features
  step_sqrt(starts_with('dist_')) %>% 
  # normalize all features
  step_normalize(all_numeric_predictors()) %>%
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .75) %>% 
  # remove ID for train set due to bugged step_nearmiss and step_tomek
  step_rm(id, skip = TRUE) %>%
  # turn all categorical features into dummy variables
  step_dummy(all_nominal_predictors()) %>%
  # upsampling with SMOTE
  step_nearmiss(fire, 
             # skip for test set
             skip = TRUE) %>% 
  # remove TOMEK-links for better class boundaries
  step_tomek(fire, 
             # skip for test set
             skip = TRUE)

# combine model specification & recipe to workflow
elanet_wf_down <- workflow() %>% 
  add_model(elanet_model) %>% 
  add_recipe(elanet_recipe_down)

# set up tuning grid
elanet_grid <- grid_regular(penalty(),
                            mixture(),
                            levels = 5)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# resample with 5-fold CV
start <- Sys.time()
elanet_tune_down <- elanet_wf_down %>% 
  tune_grid(
    resamples = cv_splits,
    grid = elanet_grid,
    metrics = metrics, 
    control = control
  )
end <- Sys.time()
end-start

# write to disk
# write_rds(elanet_tune_down, "03_outputs/GLM_tune_downsampled.rds")
# read from disk
elanet_tune_down <- read_rds("03_outputs/GLM_tune_downsampled.rds")

# show metrics
collect_metrics(elanet_tune_down)

# select best tuning specification
best_elanet_down <- select_best(elanet_tune_down, "classification_cost_penalized")

# finalize workflow with best tuning parameters
final_elanet_wf_down <- elanet_wf_down %>% 
  finalize_workflow(best_elanet_down)

# fit final elanet model
final_elanet_fit_down <- final_elanet_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# write to disk
# write_rds(final_elanet_fit_down, "03_outputs/GLM_final_downsampled.rds")
# read from disk
final_elanet_fit_down <- read_rds("03_outputs/GLM_final_downsampled.rds")

# metrics
final_elanet_fit_down %>%
  collect_metrics()

# ROC curve
final_elanet_fit_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# Confusion Matrix
final_elanet_fit_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
