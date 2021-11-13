library(ranger)

# specify model
rf_model <- 
  # enable tuning of hyperparameters
  rand_forest(mtry = tune(), 
              min_n = tune(),
              trees = 500) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

# Upsampling with SMOTE ---------------------------------------------------

# preprocessing recipe
rf_recipe_up <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>% 
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .75) %>% 
  # remove ID for train set due to bugged step_nearmiss and step_tomek
  step_rm(id, skip = TRUE) %>% 
  # create dummies for categorical features
  step_dummy(all_nominal_predictors()) %>% 
  # downsampling with NearMiss 1
  step_smote(fire,
             # skip for test set
             skip = TRUE) %>% 
  # remove TOMEK-links for better class boundaries
  step_tomek(fire, 
             # skip for test set
             skip = TRUE)

# bundle model and recipe to workflow
rf_workflow_up <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe_up)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# tune with 5-fold CV
start <- Sys.time()
rf_tune_up <- rf_workflow_up %>% 
  # set up tuning grid
  tune_grid(
    resamples = cv_splits,
    grid = 20,
    metrics = metrics, 
    control = control
  )
end <- Sys.time()
end-start

# write to disk
# write_rds(rf_tune_up, "03_outputs/RF_tuned_upsampled.rds")
# read from disk
rf_tune_up <- read_rds("03_outputs/RF_tuned_upsampled.rds")

# show metrics
collect_metrics(rf_tune_up)
show_best(rf_tune_up, "f_meas")
show_best(rf_tune_up, "roc_auc")
show_best(rf_tune_up, "classification_cost_penalized")

# select best tuning specification
best_rf_up <- select_best(rf_tune_up, "classification_cost_penalized")

# finalize workflow with best tuning parameters
best_rf_wf_up <- rf_workflow_up %>% 
  finalize_workflow(best_rf_up)

# fit final RF model
rf_fit_final_up <- best_rf_wf_up %>%
  last_fit(split = t_split, 
           metrics = metrics)

# write to disk
# write_rds(rf_fit_final_up, "03_outputs/RF_final_upsampled.rds")
# read from disk
rf_fit_final_up <- read_rds("03_outputs/RF_final_upsampled.rds")

# shut down workers
stopCluster(cl = cl)

# metrics
rf_fit_final_up %>%
  collect_metrics()

# ROC curve
rf_fit_final_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_fit_final_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampling with NearMiss 1 --------------------------------------------

# preprocessing recipe
rf_recipe_down <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>% 
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .75) %>% 
  # remove ID for train set due to bugged step_nearmiss and step_tomek
  step_rm(id, skip = TRUE) %>% 
  # create dummies for categorical features
  step_dummy(all_nominal_predictors()) %>% 
  # downsampling with NearMiss 1
  step_nearmiss(fire,
                # majority to minority class ratio
                under_ratio = 2,
                # skip for test set
                skip = TRUE) %>% 
  # remove TOMEK-links for better class boundaries
  step_tomek(fire, 
             # skip for test set
             skip = TRUE)

# bundle model and recipe to workflow
rf_workflow_down <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# tune with 5-fold CV
start <- Sys.time()
rf_tune_down <- rf_workflow_down %>% 
  # set up tuning grid
  tune_grid(
    resamples = cv_splits,
    grid = 20,
    metrics = metrics, 
    control = control
  )
end <- Sys.time()
end-start

# write to disk
# write_rds(rf_tune_down, "03_outputs/RF_tuned_downsampled.rds")
# read from disk
rf_tune_down <- read_rds("03_outputs/RF_tuned_downsampled.rds")

# show metrics
collect_metrics(rf_tune_down)
show_best(rf_tune_down, "f_meas")
show_best(rf_tune_down, "roc_auc")
show_best(rf_tune_down, "classification_cost_penalized")

# select best tuning specification
best_rf_down <- select_best(rf_tune_down, "classification_cost_penalized")

# finalize workflow with best tuning parameters
best_rf_wf_down <- rf_workflow_down %>% 
  finalize_workflow(best_rf_down)

# fit final RF model
rf_fit_final_down <- best_rf_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# metrics
rf_fit_final_down %>%
  collect_metrics()

# ROC curve
rf_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_fit_final_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
