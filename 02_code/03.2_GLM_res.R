# specify model
glm_model <- logistic_reg() %>% 
  set_engine("glm") %>% 
  set_mode("classification")

# Upsampling using SMOTE --------------------------------------------------

# preprocessing recipe (upsampling)
glm_recipe_up <-  recipe(fire ~ ., data = data_train) %>% 
  # remove id from predictors
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, 
          recreational_routes, starts_with('perc_yes')) %>%
  # power transformation for skewed distance features
  step_sqrt(starts_with('dist_')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9) %>% 
  # remove ID for train set due to bugged step_nearmiss and step_tomek
  step_rm(id, skip = TRUE) %>%
  # turn all categorical features into dummy variables
  step_dummy(all_nominal_predictors()) %>%
  # upsampling with SMOTE
  step_smote(fire, 
             # skip for test set
             skip = TRUE) %>% 
  # remove TOMEK-links for better class boundaries
  step_tomek(fire, 
             # skip for test set
             skip = TRUE)

# bundle model and recipe to workflow
glm_workflow_up <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_recipe_up)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit model
start <- Sys.time()
glm_res_up <- glm_workflow_up %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

# write to disk
# write_rds(glm_res_up, "03_outputs/GLM_res_upsampled.rds")
# read from disk
glm_res_up <- read_rds("03_outputs/GLM_res_upsampled.rds")

# metrics of resampled fit
collect_metrics(glm_res_up)

# summarize within-fold predictions
glm_preds_up <- collect_predictions(glm_res_up, 
                                    summarize = TRUE)

# plot ROC curve
glm_preds_up %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
glm_confmat_up <- glm_preds_up %>% 
  conf_mat(truth = fire, estimate = .pred_class)
glm_confmat_up

# additional metrics 
summary(glm_confmat_up)

# Downsampling using NearMiss 1 -------------------------------------------

# preprocessing recipe (downsampling)
glm_recipe_down <- recipe(fire ~ ., data = data_train) %>%
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
glm_workflow_down <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_recipe_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit model
start <- Sys.time()
glm_res_down <- glm_workflow_down %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control
  )
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

# write to disk
# write_rds(glm_res_down, "03_outputs/GLM_res_downsampled.rds")
# read from disk
glm_res_down <- read_rds("03_outputs/GLM_res_downsampled.rds")

# metrics of resampled fit
collect_metrics(glm_res_down)

# summarize within-fold predictions
glm_preds_down <- collect_predictions(glm_res_down, 
                                      summarize = TRUE)

# plot ROC curve
glm_preds_down %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
glm_confmat_down <- glm_preds_down %>% 
  conf_mat(truth = fire, estimate = .pred_class)
glm_confmat_down

# additional metrics 
summary(glm_confmat_down)
