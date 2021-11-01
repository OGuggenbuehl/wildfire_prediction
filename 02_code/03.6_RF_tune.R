library(ranger)

# specify model
rf_model <- 
  # enable tuning of hyperparameters
  rand_forest(mtry = tune(), 
              min_n = tune(),
              trees = 500) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

# preprocessing recipe
rf_recipe <- recipe(fire ~ ., data = data_train) %>% 
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
rf_workflow <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe)

# register parallel-processing backend
registerDoParallel(cl)

# inspect model and tuning parameters
rf_model %>%    
  parameters() 

# tune with 5-fold CV
start <- Sys.time()
rf_tune <- rf_workflow %>% 
  # set up tuning grid
  tune_grid(
    resamples = cv_splits,
    grid = 20,
    metrics = metrics, 
    control = control
  )
end <- Sys.time()
end-start

write_rds(rf_tune, "03_outputs/RF_tuned_downsampled.rds")
rf_tune <- read_rds("03_outputs/RF_tuned_downsampled.rds")

# show metrics
collect_metrics(rf_tune)
show_best(rf_tune, "f_meas")
show_best(rf_tune, "mn_log_loss")
show_best(rf_tune, "roc_auc")

# manually create tuning grid based on these results
rf_grid <- grid_regular(mtry(range = c(12, 36)),
                        min_n(range = c(3, 15)), 
                        levels = 5)

rf_tune_manual_downsampled <- rf_workflow %>% 
  tune_grid(
  resamples = cv_splits,
  grid = rf_grid,
  metrics = metrics, 
  control = control
)

# write to disk
write_rds(rf_tune_manual_downsampled, "03_outputs/RF_tune_manual_downsampled.rds")
# read from disk
rf_tune_manual_downsampled <- read_rds("03_outputs/RF_tune_manual_downsampled.rds")

# show metrics
collect_metrics(rf_tune_manual)
show_best(rf_tune_manual, "f_meas")
show_best(rf_tune_manual, "roc_auc")
show_best(rf_tune_manual, "mn_log_loss")

# select best tuning specification
best_rf <- select_best(rf_tune_manual, "mn_log_loss")

# finalize workflow with best tuning parameters
best_rf_wf <- rf_workflow %>% 
  finalize_workflow(best_rf)

# fit final RF model
rf_fit_final <- best_rf_wf %>%
  last_fit(split = t_split, 
           metrics = metrics)

# metrics
rf_fit_final %>%
  collect_metrics()

# ROC curve
rf_fit_final %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()
