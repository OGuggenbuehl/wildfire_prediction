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