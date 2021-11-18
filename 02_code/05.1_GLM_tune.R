library(glmnet)

# specify model
elanet_model <- 
  # enable tuning of hyperparameters
  logistic_reg(penalty = tune(), 
               mixture = tune()) %>% 
  set_engine("glmnet") %>% 
  set_mode("classification")

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

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(elanet_tune_down, "03_outputs/models/GLM_tune_randomsampled.rds")
# read from disk
elanet_tune_down <- read_rds("03_outputs/models/GLM_tune_randomsampled.rds")

# show metrics
collect_metrics(elanet_tune_down)

# select best tuning specification
best_elanet_down <- select_best(elanet_tune_down, "roc_auc")

# finalize workflow with best tuning parameters
final_elanet_wf_down <- elanet_wf_down %>% 
  finalize_workflow(best_elanet_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final elanet model
final_elanet_fit_down <- final_elanet_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

write_rds(final_elanet_fit_down, "03_outputs/models/GLM_final_randomsampled.rds")
