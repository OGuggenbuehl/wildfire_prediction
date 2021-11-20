# Upsampled ---------------------------------------------------------------

# read from disk
final_elanet_fit_up <- read_rds("03_outputs/models/GLM_final_upsampled.rds")

# metrics
glm_tuned_up_metrics <- final_elanet_fit_up %>%
  collect_metrics() %>% 
  mutate(model = 'GLM_tuned_upsampled')

# ROC curve
final_elanet_fit_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve elastic net regression",
    subtitle = "upsampled, temporal split (2016)"
  )

ggsave("03_outputs/plots/roc_glm_up_time.png")

# Confusion Matrix
final_elanet_fit_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# Downsampled -------------------------------------------------------------

# read from disk
final_elanet_fit_down <- read_rds("03_outputs/models/GLM_final_downsampled.rds")

# metrics
glm_tuned_down_metrics <- final_elanet_fit_down %>%
  collect_metrics() %>% 
  mutate(model = 'GLM_tuned_downsampled')

# ROC curve
final_elanet_fit_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve elastic net regression",
    subtitle = "downsampled, temporal split (2016)"
  )

ggsave("03_outputs/plots/roc_glm_down_time.png")

# Confusion Matrix
final_elanet_fit_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
