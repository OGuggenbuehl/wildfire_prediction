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

# write to disk
write_rds(xgb_tune_down, "03_outputs/models/XGB_tune_randomsampled.rds")
# read from disk
xgb_tune_down <- read_rds("03_outputs/models/XGB_tune_randomsampled.rds")

# show metrics
collect_metrics(xgb_tune_down) %>% 
  select(-c(n, std_err, .config)) %>% 
  pivot_wider(names_from = .metric, values_from = mean)

# select best tuning specification
best_xgb_down <- select_best(xgb_tune_down, "roc_auc")

# finalize workflow with best tuning parameters
best_xgb_wf_down <- xgb_workflow_down %>% 
  finalize_workflow(best_xgb_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final model
xgb_fit_final_down <- best_xgb_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

write_rds(xgb_fit_final_down, "03_outputs/models/XGB_final_randomsampled.rds")
