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
            threshold = .75) %>% 
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
write_rds(glm_res_up, "03_outputs/models/GLM_res_upsampled.rds")

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
            threshold = .75) %>%
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
                control = control)
end <- Sys.time()
end-start

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(glm_res_down, "03_outputs/models/GLM_res_downsampled.rds")
