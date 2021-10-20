# specify model
rf_model <- rand_forest(mtry = tune(), 
                        min_n = tune(), 
                        trees = 1000) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

# preprocessing recipe
rf_recipe <- recipe(fire ~ ., data = data) %>% 
  update_role(id, season, new_role = "ID")



# bundle model and recipe to workflow
rf_workflow <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe)

# fit model
start <- Sys.time()
rf_fit <- rf_workflow %>% 
  fit(data = data_train)
end <- Sys.time()
end-start

# predict with test data
rf_preds <- predict(rf_fit, data_test)

# number of positive predictions
rf_preds %>% 
  pull(.pred_class) %>% 
  table()

# add predicted values and probabilities to data set
rf_aug <- 
  augment(rf_fit, data_test)

# inspect
rf_aug %>%
  select(fire, .pred_class, .pred_TRUE, .pred_FALSE, 
         id, year, month)

# plot ROC curve
rf_aug %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# compute ROC AUC
rf_aug %>% 
  roc_auc(truth = fire, .pred_FALSE)

# confusion matrix
rf_confmat <- rf_aug %>% 
  conf_mat(truth = fire, estimate = .pred_class)
rf_confmat

# additional metrics 
summary(rf_confmat, 
        event_level = 'second')