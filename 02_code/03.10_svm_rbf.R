library(kernlab)

# specify model
svm_rbf_model <- svm_rbf(cost = tune(), 
                         rbf_sigma = tune()) %>%
  set_mode("classification") %>%
  set_engine("kernlab")

# preprocessing recipe
svm_recipe <-  recipe(fire ~ ., data = data_train) %>% 
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
  # normalize features
  step_normalize(all_numeric_predictors()) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9)

# bundle model and recipe to workflow
svm_rbf_workflow <- workflow() %>% 
  add_model(svm_rbf_model) %>% 
  add_recipe(svm_recipe)

# register parallel-processing backend
registerDoParallel(cl)

# fit model
start <- Sys.time()
svm_rbf_res <- svm_rbf_workflow %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control_resamples(
                  verbose = TRUE,
                  save_pred = TRUE,
                  event_level = "second", 
                  allow_par = TRUE, 
                  parallel_over = 'resamples')
  )
end <- Sys.time()
end-start

write_rds(svm_rbf_res, "03_outputs/SVM_rbf_res.rds")
# svm_rbf_res <- read_rds("03_outputs/SVM_rbf_res.rds")

# metrics of resampled fit
collect_metrics(svm_rbf_res)

# summarize within-fold predictions
svm_rbf_preds <- collect_predictions(svm_rbf_res, 
                                 summarize = TRUE)

# plot ROC curve
svm_rbf_preds %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# confusion matrix
svm_rbf_confmat <- svm_rbf_preds %>% 
  conf_mat(truth = fire, estimate = .pred_class)
svm_rbf_confmat