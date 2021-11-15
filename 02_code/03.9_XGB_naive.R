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
  step_rm(lake, river, powerline, road, 
          recreational_routes, starts_with('perc_yes')) %>% 
  # create dummies
  step_dummy(all_nominal_predictors()) %>%
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .75)

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

# write to disk
write_rds(xgb_fit, "03_outputs/XGB_naive.rds")
