library(ranger)

# specify model
rf_model <- rand_forest() %>% 
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

# fit model
start <- Sys.time()
rf_res <- rf_workflow %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control
  )
end <- Sys.time()
end-start

write_rds(rf_res, "03_outputs/RF_res_downsampled.rds")
rf_res <- read_rds("03_outputs/RF_res_downsampled.rds")

# metrics of resampled fit
collect_metrics(rf_res)

# summarize within-fold predictions
rf_preds <- collect_predictions(rf_res, 
                                summarize = TRUE)

# plot ROC curve
rf_preds %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# confusion matrix
rf_confmat <- rf_preds %>% 
  conf_mat(truth = fire, estimate = .pred_class)
rf_confmat
