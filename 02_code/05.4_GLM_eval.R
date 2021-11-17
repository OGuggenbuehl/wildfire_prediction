final_elanet_fit_down <- read_rds("03_outputs/models/GLM_final_randomsampled.rds")

# metrics
glm_tuned_down_metrics <- final_elanet_fit_down %>%
  collect_metrics() %>% 
  mutate(model = 'GLM_down_randomsplit')

# ROC curve
final_elanet_fit_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# Confusion Matrix
final_elanet_fit_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)