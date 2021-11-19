library(ranger)

# specify model
rf_model <- 
  # enable tuning of hyperparameters
  rand_forest(mtry = tune(), 
              min_n = tune(),
              trees = 500) %>% 
  set_engine("ranger", importance = "impurity") %>% 
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

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(rf_tune_up, "03_outputs/models/RF_tuned_upsampled.rds")

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

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(rf_tune_down, "03_outputs/models/RF_tuned_downsampled.rds")
