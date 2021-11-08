# specify model
glm_model <- logistic_reg() %>% 
  set_engine("glm") %>% 
  set_mode("classification")

# preprocessing recipe 
glm_recipe <-  recipe(fire ~ ., data = data_train) %>% 
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
            threshold = .9)

# bundle model and recipe to workflow
glm_workflow <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_recipe)

# fit model
start <- Sys.time()
glm_fit <- glm_workflow %>%
  fit(data = data_train)
end <- Sys.time()
end-start

# write to disk
# write_rds(glm_fit, "03_outputs/GLM_naive.rds")
# read from disk
glm_fit <- read_rds("03_outputs/GLM_naive.rds")

glm_naive_preds <- predict(glm_fit, type = 'prob',
                           new_data = data_test) %>% 
  bind_cols(data_test)

# plot ROC curve
glm_naive_preds %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
glm_confmat <- predict(glm_fit, type = 'class',
                       new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
glm_confmat

# additional metrics 
summary(glm_confmat)
