# Upsampling with SMOTE ---------------------------------------------------

# read from disk
glm_res_up <- read_rds("03_outputs/models/GLM_res_upsampled.rds")

# metrics of resampled fit
glm_res_up_metrics <- collect_metrics(glm_res_up) %>% 
  mutate(model = 'GLM_res_upsampled')

# summarize within-fold predictions
glm_preds_up <- collect_predictions(glm_res_up, 
                                    summarize = TRUE)

# plot ROC curve
glm_preds_up %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
glm_preds_up %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampling with NearMiss1  --------------------------------------------

# read from disk
glm_res_down <- read_rds("03_outputs/models/GLM_res_downsampled.rds")

# metrics of resampled fit
glm_res_down_metrics <- collect_metrics(glm_res_down) %>% 
  mutate(model = 'GLM_res_downsampled')

# summarize within-fold predictions
glm_preds_down <- collect_predictions(glm_res_down, 
                                      summarize = TRUE)

# plot ROC curve
glm_preds_down %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
glm_preds_down %>% 
  conf_mat(truth = fire, estimate = .pred_class)
