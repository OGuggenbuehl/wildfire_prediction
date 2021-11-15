# read from disk
xgb_fit <- read_rds("03_outputs/XGB_naive.rds")

# predictions
xgb_naive_preds <- predict(xgb_fit, type = 'prob',
                           new_data = data_test) %>% 
  bind_cols(data_test)

# plot ROC curve
xgb_naive_preds %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_confmat <- predict(xgb_fit, type = 'class',
                       new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
xgb_confmat

# metrics 
xgb_naive_metrics <- summary(xgb_confmat) %>% 
  bind_rows(classification_cost_penalized(truth = fire, 
                                          .pred_fire, 
                                          data = xgb_naive_preds)) %>% 
  mutate(model = 'XGB_naive') %>% 
  select(-.estimator)
