library(ranger)

# specify model
rf_model <- rand_forest() %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

# Upsampling with SMOTE ---------------------------------------------------

# preprocessing recipe
rf_recipe_up <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, DPA_agency, 
          recreational_routes, starts_with('perc_yes')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>% 
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9) %>% 
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

# fit model
start <- Sys.time()
rf_res_up <- rf_workflow_up %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

write_rds(rf_res_up, "03_outputs/RF_res_downsampled.rds")
rf_res_up <- read_rds("03_outputs/RF_res_downsampled.rds")

# metrics of resampled fit
collect_metrics(rf_res_up)

# summarize within-fold predictions
rf_preds_up <- collect_predictions(rf_res_up, 
                                summarize = TRUE)

# plot ROC curve
rf_preds_up %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# confusion matrix
rf_confmat_up <- rf_preds_up %>% 
  conf_mat(truth = fire, estimate = .pred_class)
rf_confmat_up

# Downsampling with NearMiss 1 --------------------------------------------

# preprocessing recipe
rf_recipe_down <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, DPA_agency, 
          recreational_routes, starts_with('perc_yes')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>% 
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9) %>% 
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

# fit model
start <- Sys.time()
rf_res_down <- rf_workflow_down %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

write_rds(rf_res_down, "03_outputs/RF_res_downsampled.rds")
rf_res_down <- read_rds("03_outputs/RF_res_downsampled.rds")

# metrics of resampled fit
collect_metrics(rf_res_down)

# summarize within-fold predictions
rf_preds_down <- collect_predictions(rf_res_down, 
                                     summarize = TRUE)

# plot ROC curve
rf_preds_down %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# confusion matrix
rf_confmat_down <- rf_preds_down %>% 
  conf_mat(truth = fire, estimate = .pred_class)
rf_confmat_down