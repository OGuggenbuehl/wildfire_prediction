final_elanet_fit_down <- read_rds("03_outputs/models/GLM_final_randomsampled.rds")

# metrics
glm_tuned_down_metrics <- final_elanet_fit_down %>%
  collect_metrics() %>% 
  mutate(model = 'GLM_down_randomsplit')

write_xlsx(glm_tuned_down_metrics, "03_outputs/tables/appendix/glm_rsampl_metrics.xlsx")

# ROC curve
final_elanet_fit_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve elastic net regression",
    subtitle = "downsampled, randomized split"
  )

ggsave("03_outputs/plots/roc_glm_rsampl.png")

# Confusion Matrix
final_elanet_fit_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)
