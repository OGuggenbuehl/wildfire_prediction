library(xgboost)

# calculate value for scale_pos_weight parameter
param <- data_train %>% 
  count(fire) %>% 
  pivot_wider(names_from = fire, values_from = n) %>% 
  mutate(scale_pos_weight = none / fire)

# specify model
xgb_model <- 
  # enable tuning of hyperparameters
  boost_tree() %>% 
  set_engine(engine = "xgboost", 
             scale_pos_weight = param$scale_pos_weight) %>% 
  set_mode("classification")

# preprocessing recipe
xgb_recipe <- recipe(fire ~ ., data = data_train) %>% 
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road, DPA_agency, 
          recreational_routes, starts_with('perc_yes')) %>% 
  # create dummies
  step_dummy(all_nominal_predictors()) %>%
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9)

# bundle model and recipe to workflow
xgb_workflow <- workflow() %>% 
  add_model(xgb_model) %>% 
  add_recipe(xgb_recipe)

# fit naive model
start <- Sys.time()
xgb_fit <- xgb_workflow %>% 
  fit(data = data_train)
end <- Sys.time()
end-start

write_rds(xgb_fit, "03_outputs/xgb_naive.rds")
xgb_fit <- read_rds("03_outputs/xgb_naive.rds")

# plot ROC curve
predict(xgb_fit, type = 'prob',
        new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_confmat <- predict(xgb_fit, type = 'class',
                      new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
xgb_confmat

# additional metrics 
summary(xgb_confmat)