library(xgboost)

# specify model
xgb_model <- 
  # enable tuning of hyperparameters
  boost_tree(trees = 500, 
             tree_depth = tune(), 
             min_n = tune(), 
             loss_reduction = tune(),
             sample_size = tune(), 
             mtry = tune(),
             learn_rate = tune()) %>% 
  set_engine("xgboost") %>% 
  set_mode("classification")


# Upsampling with SMOTE ---------------------------------------------------

# preprocessing recipe
xgb_recipe_up <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, 
          recreational_routes, starts_with('perc_yes')) %>% 
  # create dummies
  step_dummy(all_nominal_predictors()) %>% 
  # upsampling with SMOTE
  step_smote(fire, 
             # skip for test set
             skip = TRUE) %>%
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9)

# bundle model and recipe to workflow
xgb_workflow_up <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(xgb_recipe_up)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# tune with 5-fold CV
start <- Sys.time()
xgb_tune_up <- xgb_workflow_up %>% 
  # set up tuning grid
  tune_grid(
    resamples = cv_splits,
    grid = 20,
    metrics = metrics, 
    control = control
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

write_rds(xgb_tune_up, "03_outputs/XGB_tuned_upsampled.rds")
xgb_tune_up <- read_rds("03_outputs/XGB_tuned_upsampled.rds")

# show metrics
collect_metrics(xgb_tune_up) %>% 
  select(-c(n, std_err, .config)) %>% 
  pivot_wider(names_from = .metric, values_from = mean) %>% View()

show_best(xgb_tune_up, "f_meas") %>% select(.metric, mean)
show_best(xgb_tune_up, "roc_auc") %>% select(.metric, mean)
show_best(xgb_tune_up, "precision") %>% select(.metric, mean)
show_best(xgb_tune_up, "recall") %>% select(.metric, mean)

# select best tuning specification
best_xgb_up <- select_best(xgb_tune_up, "f_meas")

# finalize workflow with best tuning parameters
best_xgb_wf_up <- xgb_workflow_up %>% 
  finalize_workflow(best_xgb_up)

# fit final RF model
xgb_fit_final_up <- best_xgb_wf_up %>%
  last_fit(split = t_split, 
           metrics = metrics)
# metrics
xgb_fit_final_up %>%
  collect_metrics()

# ROC curve
xgb_fit_final_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_confmat_up <- xgb_fit_final_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
xgb_confmat_up

# Downsampling with NearMiss 1 --------------------------------------------

# preprocessing recipe
xgb_recipe_down <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, 
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
xgb_workflow_down <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(xgb_recipe_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# tune with 5-fold CV
start <- Sys.time()
xgb_tune_down <- xgb_workflow_down %>% 
  # set up tuning grid
  tune_grid(
    resamples = cv_splits,
    grid = 40,
    metrics = metrics, 
    control = control
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

write_rds(xgb_tune_down, "03_outputs/XGB_tuned_downsampled.rds")
xgb_tune_down <- read_rds("03_outputs/XGB_tuned_downsampled.rds")

# show metrics
collect_metrics(xgb_tune_down) %>% 
  select(-c(n, std_err, .config)) %>% 
  pivot_wider(names_from = .metric, values_from = mean) %>% View()
show_best(xgb_tune_down, "f_meas") 
show_best(xgb_tune_down, "roc_auc")

# select best tuning specification
best_xgb_down <- select_best(xgb_tune_down, "recall")

# finalize workflow with best tuning parameters
best_xgb_wf_down <- xgb_workflow_down %>% 
  finalize_workflow(best_xgb_down)

# fit final model
xgb_fit_final_down <- best_xgb_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)
# metrics
xgb_fit_final_down %>%
  collect_metrics()

# ROC curve
xgb_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_confmat_down <- xgb_fit_final_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
xgb_confmat_down
