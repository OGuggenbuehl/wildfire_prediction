library(ranger)

# specify model
rf_model <- 
  # enable tuning of hyperparameters
  rand_forest() %>% 
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
            threshold = .9)

# bundle model and recipe to workflow
rf_workflow <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe)

# fit naive model
start <- Sys.time()
rf_fit <- rf_workflow %>% 
  # set up tuning grid
  fit(
    data = data_train)
end <- Sys.time()
end-start

# write to disk
write_rds(rf_fit, "03_outputs/RF_naive.rds")
# read from disk
rf_fit <- read_rds("03_outputs/RF_naive.rds")

# plot ROC curve
predict(rf_fit, type = 'prob',
        new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_confmat <- predict(rf_fit, type = 'class',
                       new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
rf_confmat

# additional metrics 
summary(rf_confmat)
