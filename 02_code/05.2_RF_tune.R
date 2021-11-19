library(ranger)

# specify model
rf_model <- 
  # enable tuning of hyperparameters
  rand_forest(mtry = tune(), 
              min_n = tune(),
              trees = 500) %>% 
  set_engine("ranger", importance = "impurity") %>% 
  set_mode("classification")

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
write_rds(rf_tune_down, "03_outputs/models/RF_tune_randomsampled.rds")
# read from disk
rf_tune_down <- read_rds("03_outputs/models/RF_tune_randomsampled.rds")

# select best tuning specification
best_rf_down <- select_best(rf_tune_down, "roc_auc")

# finalize workflow with best tuning parameters
best_rf_wf_down <- rf_workflow_down %>% 
  finalize_workflow(best_rf_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final RF model
rf_fit_final_down <- best_rf_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

write_rds(rf_fit_final_down, "03_outputs/models/RF_final_randomsampled.rds")
