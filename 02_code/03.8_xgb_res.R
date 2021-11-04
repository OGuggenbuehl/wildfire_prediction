library(xgboost)

# specify model
xgb_model <- boost_tree() %>% 
  set_engine("xgboost") %>% 
  set_mode("classification")

# Upsampling --------------------------------------------------------------

# preprocessing recipe
xgb_recipe_up <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, year, DPA_agency, 
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
xgb_workflow_up <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(xgb_recipe_up)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit model
start <- Sys.time()
xgb_res_up <- xgb_workflow_up %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control_resamples(
                  verbose = TRUE,
                  save_pred = TRUE,
                  allow_par = FALSE)
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

# write_rds(xgb_res_up, "03_outputs/XGB_res_upsampled.rds")
xgb_res_up <- read_rds("03_outputs/XGB_res_upsampled.rds")

# metrics of resampled fit
collect_metrics(xgb_res_up)

# summarize within-fold predictions
xgb_preds_up <- collect_predictions(xgb_res_up, 
                                    summarize = TRUE)

# plot ROC curve
xgb_preds_up %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_confmat_up <- xgb_preds_up %>% 
  conf_mat(truth = fire, estimate = .pred_class)
xgb_confmat_up

# Downsampling ------------------------------------------------------------

# preprocessing recipe
xgb_recipe_down <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, DPA_agency, 
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
xgb_workflow_down <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(xgb_recipe_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit model
start <- Sys.time()
xgb_res_down <- xgb_workflow_down %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

write_rds(xgb_res_down, "03_outputs/XGB_res_downsampled.rds")
xgb_res_down <- read_rds("03_outputs/XGB_res_downsampled.rds")

# metrics of resampled fit
collect_metrics(xgb_res_down)

# summarize within-fold predictions
xgb_preds_down <- collect_predictions(xgb_res_down, 
                                      summarize = TRUE)

# plot ROC curve
xgb_preds_down %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_confmat_down <- xgb_preds_down %>% 
  conf_mat(truth = fire, estimate = .pred_class)
xgb_confmat_down
