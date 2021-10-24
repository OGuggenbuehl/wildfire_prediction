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

# preprocessing recipe
xgb_recipe <- recipe(fire ~ ., data = data_train) %>% 
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
xgb_workflow <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(xgb_recipe)

# register parallel-processing backend
registerDoParallel(cl)

# inspect model and tuning parameters
xgb_model %>%    
  parameters() 

# tune with 5-fold CV
start <- Sys.time()
xgb_tune <- xgb_workflow %>% 
  # set up tuning grid
  tune_grid(
    resamples = cv_splits,
    grid = 20,
    metrics = metrics, 
    control = control_grid(save_pred = TRUE, 
                           verbose = TRUE, 
                           event_level = 'second', 
                           allow_par = TRUE, 
                           parallel_over = 'resamples')
  )
end <- Sys.time()
end-start

write_rds(xgb_tune, "03_outputs/xgb_tuned.rds")
xgb_tune <- read_rds("03_outputs/xgb_tuned.rds")

# show metrics
collect_metrics(xgb_tune)
show_best(xgb_tune, "f_meas")
show_best(xgb_tune, "roc_auc")

# manually create tuning grid based on these results
xgb_grid <- grid_regular(mtry(range = c(2, 10)),
                        min_n(range = c(4, 16)), 
                        levels = 5)

# select best tuning specification
best_rf <- select_best(xgb_tune_manual, "f_meas")

# finalize workflow with best tuning parameters
best_xgb_wf <- xgb_workflow %>% 
  finalize_workflow(best_rf)

# fit final RF model
xgb_fit_final <- best_xgb_wf %>%
  last_fit(split = t_split, 
           metrics = metrics)

# metrics
xgb_fit_final %>%
  collect_metrics()

# ROC curve
xgb_fit_final %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_FALSE) %>% 
  autoplot()