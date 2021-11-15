# read from disk
xgb_fit <- read_rds("03_outputs/XGB_naive.rds")

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