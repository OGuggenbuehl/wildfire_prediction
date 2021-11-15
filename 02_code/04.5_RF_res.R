# Upsampled ---------------------------------------------------------------

# read from disk
rf_res_up <- read_rds("03_outputs/RF_res_upsampled.rds")

# metrics of resampled fit
rf_res_up_metrics <- collect_metrics(rf_res_up) %>% 
  mutate(model = 'RF_res_upsampled')

# summarize within-fold predictions
rf_preds_up <- collect_predictions(rf_res_up, 
                                   summarize = TRUE)

# plot ROC curve
rf_preds_up %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_preds_up %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampled -------------------------------------------------------------

# read from disk
rf_res_down <- read_rds("03_outputs/RF_res_downsampled.rds")

# metrics of resampled fit
rf_res_down_metrics <- collect_metrics(rf_res_down) %>% 
  mutate(model = 'RF_res_downsampled')

# summarize within-fold predictions
rf_preds_down <- collect_predictions(rf_res_down, 
                                     summarize = TRUE)

# plot ROC curve
rf_preds_down %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_preds_down %>% 
  conf_mat(truth = fire, estimate = .pred_class)
