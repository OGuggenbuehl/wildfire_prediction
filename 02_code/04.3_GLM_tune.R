# Upsampled ---------------------------------------------------------------

# read from disk
final_elanet_fit_up <- read_rds("03_outputs/GLM_final_upsampled.rds")

# metrics
glm_tuned_up_metrics <- final_elanet_fit_up %>%
  collect_metrics() %>% 
  mutate(model = 'GLM_tuned_upsampled')

# ROC curve
final_elanet_fit_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# Confusion Matrix
final_elanet_fit_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampled -------------------------------------------------------------

# read from disk
final_elanet_fit_down <- read_rds("03_outputs/GLM_final_downsampled.rds")

# metrics
glm_tuned_down_metrics <- final_elanet_fit_down %>%
  collect_metrics() %>% 
  mutate(model = 'GLM_tuned_downsampled')

# ROC curve
final_elanet_fit_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# Confusion Matrix
final_elanet_fit_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
