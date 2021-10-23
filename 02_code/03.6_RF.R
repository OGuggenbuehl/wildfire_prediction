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
rf_recipe <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
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
                      v = 5)

# inspect model and tuning parameters
rf_model %>%    
  parameters() 

# tune with 10-fold CV
start <- Sys.time()
rf_tune <- rf_workflow %>% 
  # set up tuning grid
  tune_grid(
    resamples = cv_splits,
    grid = 10,
    metrics = metrics, 
    control = control_grid(save_pred = TRUE, 
                           verbose = TRUE, 
                           event_level = 'second', 
                           allow_par = TRUE, 
                           parallel_over = 'resamples'), 
  )
end <- Sys.time()
end-start

write_rds(rf_tune, "03_outputs/rf_tuned.rds")

# show metrics
collect_metrics(rf_tune)
show_best(rf_tune, "f_meas")
show_best(rf_tune, "roc_auc")

# select best tuning specification
best_rf <- select_best(rf_tune, "f_meas")

# finalize workflow with best tuning parameters
final_rf_wf <- rf_workflow %>% 
  finalize_workflow(best_rf)

# fit final RF model
final_rf_fit <- final_rf_wf %>%
  last_fit(split = t_split, 
           metrics = metrics)

# metrics
final_rf_fit %>%
  collect_metrics()

# ROC curve
final_rf_fit %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_FALSE) %>% 
  autoplot()
