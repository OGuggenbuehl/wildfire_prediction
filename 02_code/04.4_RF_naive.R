# read from disk
rf_fit <- read_rds("03_outputs/RF_naive.rds")

# predictions
rf_naive_preds <- predict(rf_fit, type = 'prob',
        new_data = data_test) %>% 
  bind_cols(data_test)

# plot ROC curve
rf_naive_preds %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_confmat <- predict(rf_fit, type = 'class',
                      new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
rf_confmat

# metrics 
rf_naive_metrics <- summary(rf_confmat) %>% 
  bind_rows(roc_auc(truth = fire, 
                    .pred_fire, 
                    data = rf_naive_preds)) %>% 
  bind_rows(classification_cost_penalized(truth = fire, 
                                          .pred_fire, 
                                          data = rf_naive_preds)) %>% 
  mutate(model = 'RF_naive') %>% 
  select(-.estimator)
