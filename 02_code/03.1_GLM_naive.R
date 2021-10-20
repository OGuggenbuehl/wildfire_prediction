# specify model
glm_model <- logistic_reg() %>% 
  set_engine("glm") %>% 
  set_mode("classification")

# preprocessing recipe
glm_naive_recipe <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID")

# bundle model and recipe to workflow
glm_naive_workflow <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_naive_recipe)

# fit model with train data
glm_naive_fit <- glm_naive_workflow %>% 
  fit(data = data_train)

# inspect coefficients
glm_naive_fit %>% 
  extract_fit_parsnip() %>% 
  tidy()

# predict with test data
glm_naive_pred <- predict(glm_naive_fit, 
                          new_data = data_test)

# number of positive predictions
glm_naive_pred %>% 
  pull(.pred_class) %>% 
  table()

# add predicted values and probabilities to data set
glm_naive_aug <- 
  augment(glm_naive_fit, data_test)

# inspect
glm_naive_aug %>%
  select(fire, .pred_class, .pred_TRUE, .pred_FALSE, 
         id, year, season)

# plot ROC curve
glm_naive_aug %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# compute ROC AUC
glm_naive_aug %>% 
  roc_auc(truth = fire, .pred_FALSE)

# confusion matrix
glm_naive_confmat <- glm_naive_aug %>% 
  conf_mat(truth = fire, estimate = .pred_class)
glm_naive_confmat

# additional metrics 
summary(glm_naive_confmat, 
        event_level = 'second')

# The model shows the typical symptoms of a heavily imbalanced data set
# very high accuracy, but the confusion matrix shows that the model
# is heavily overfit to negative events --> upsampling needed
# multicollinearity also seems to be a problem --> remove highly correlated features
