library(ranger)

# specify model
rf_model <- 
  # enable tuning of hyperparameters
  rand_forest(mtry = tune(), 
              min_n = tune(), 
              trees = 1000) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

# preprocessing recipe
rf_recipe <- recipe(fire ~ ., data = data) %>% 
  update_role(id, season, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>%
  # upsampling with ROSE
  step_rose(fire, 
             # skip for test set
             skip = TRUE) %>%
  # remove 0-variance features
  step_zv(all_predictors())%>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9)

# bundle model and recipe to workflow
rf_workflow <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe)

# set up parallel-processing backend
all_cores <- parallel::detectCores(logical = FALSE)

library(doParallel)
cl <- makePSOCKcluster(all_cores)
registerDoParallel(cl)

# specify metrics
metrics <- metric_set(roc_auc, accuracy, sens, spec, 
                      f_meas, precision, recall)

# create splits for 10-fold CV resampling
cv_splits <- vfold_cv(data_train, 
                      v = 10)

# set up tuning grid
rf_grid <- rf_model %>%
  parameters() %>%
  finalize(select(data_train, -fire)) %>%  
  grid_max_entropy(size = 25)

# tune with 10-fold CV
start <- Sys.time()
rf_tune <- rf_workflow %>% 
  tune_grid(
    resamples = cv_splits,
    grid = rf_grid,
    metrics = metrics, 
    control = control_grid(save_pred = TRUE, 
                           verbose = TRUE, 
                           event_level = 'second', 
                           allow_par = TRUE, 
                           parallel_over = 'resamples'), 
  )
end <- Sys.time()
end-start
