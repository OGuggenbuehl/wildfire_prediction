# Upsampling --------------------------------------------------------------

# read from disk
xgb_fit_final_up <- read_rds("03_outputs/XGB_final_upsampled.rds")

# metrics
xgb_fit_final_up %>%
  collect_metrics()

# ROC curve
xgb_fit_final_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_fit_final_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampling ------------------------------------------------------------

# read from disk
xgb_fit_final_down <- read_rds("03_outputs/XGB_final_downsampled.rds")

# metrics
xgb_fit_final_down %>%
  collect_metrics()

# ROC curve
xgb_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_fit_final_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)