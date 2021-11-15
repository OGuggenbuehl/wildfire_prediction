# Upsampling --------------------------------------------------------------

# read from disk
xgb_res_up <- read_rds("03_outputs/XGB_res_upsampled.rds")

# metrics of resampled fit
collect_metrics(xgb_res_up)

# summarize within-fold predictions
xgb_preds_up <- collect_predictions(xgb_res_up, 
                                    summarize = TRUE)

# plot ROC curve
xgb_preds_up %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_preds_up %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampling ------------------------------------------------------------

# read from disk
xgb_res_down <- read_rds("03_outputs/XGB_res_downsampled.rds")

# metrics of resampled fit
collect_metrics(xgb_res_down)

# summarize within-fold predictions
xgb_preds_down <- collect_predictions(xgb_res_down, 
                                      summarize = TRUE)

# plot ROC curve
xgb_preds_down %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
xgb_preds_down %>% 
  conf_mat(truth = fire, estimate = .pred_class)
