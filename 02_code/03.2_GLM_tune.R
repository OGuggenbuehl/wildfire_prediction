library(glmnet)

# specify model
elanet_model <- 
  # enable tuning of hyperparameters
  logistic_reg(penalty = tune(), 
               mixture = tune()) %>% 
  set_engine("glmnet") %>% 
  set_mode("classification")

# create recipe
elanet_recipe <-  recipe(fire ~ ., data = data_train) %>% 
  # remove id from predictors
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>%
  # turn all categorical features into dummy variables
  step_dummy(all_nominal_predictors()) %>%
  # upsampling with SMOTE
  step_smote(fire, 
             # skip for test set
             skip = TRUE) %>%
  # power transformation for skewed distance features
  step_sqrt(starts_with('dist_')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9) %>% 
  # normalize all features
  step_normalize(all_numeric_predictors())

# combine model specification & recipe to workflow
elanet_wf <- workflow() %>% 
  add_model(elanet_model) %>% 
  add_recipe(elanet_recipe)

# register parallel-processing backend
registerDoParallel(cl)

# set up tuning grid
elanet_grid <- grid_regular(penalty(),
                            mixture(),
                            levels = 5)

# tune with 10-fold CV
start <- Sys.time()
elanet_tune <- elanet_wf %>% 
  tune_grid(
    resamples = cv_splits,
    grid = elanet_grid,
    metrics = metrics, 
    control = control
    )
end <- Sys.time()
end-start

# write_rds(elanet_tune, "03_outputs/elanet_tune.rds")
elanet_tune <- read_rds("03_outputs/elanet_tune_upsampled.rds")

# show metrics
collect_metrics(elanet_tune)
show_best(elanet_tune, "f_meas")
show_best(elanet_tune, "roc_auc")

# select best tuning specification
best_elanet <- select_best(elanet_tune, "f_meas")

# finalize workflow with best tuning parameters
final_elanet_wf <- elanet_wf %>% 
  finalize_workflow(best_elanet)

# fit final elanet model
final_elanet_fit <- final_elanet_wf %>%
  last_fit(split = t_split, 
           metrics = metrics)

# metrics
final_elanet_fit %>%
  collect_metrics()

# ROC curve
final_elanet_fit %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_FALSE) %>% 
  autoplot()

# ROC curve
final_elanet_fit %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
