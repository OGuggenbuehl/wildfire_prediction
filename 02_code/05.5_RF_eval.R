rf_fit_final_down <- read_rds("03_outputs/RF_final_randomsampled.rds")

# metrics
rf_tuned_down_metrics <- rf_fit_final_down %>%
  collect_metrics() %>% 
  mutate(model = 'RF_tuned_downsampled')

# ROC curve
rf_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_fit_final_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)