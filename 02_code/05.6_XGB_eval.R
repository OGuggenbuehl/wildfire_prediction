xgb_fit_final_down <- read_rds("03_outputs/XGB_final_randomsampled.rds")

# metrics
xgb_tuned_down_metrics <- xgb_fit_final_down %>%
  collect_metrics() %>% 
  mutate(model = 'XGB_tuned_downsampled')

# ROC curve
xgb_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_fit_final_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)