# Upsampled ---------------------------------------------------------------

# read from disk
final_elanet_fit_up <- read_rds("03_outputs/GLM_final_upsampled.rds")

# metrics
final_elanet_fit_up %>%
  collect_metrics()

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
final_elanet_fit_down %>%
  collect_metrics()

# ROC curve
final_elanet_fit_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# Confusion Matrix
final_elanet_fit_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
