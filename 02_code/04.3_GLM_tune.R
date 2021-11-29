# Upsampled ---------------------------------------------------------------

# read from disk
final_elanet_fit_up <- read_rds("03_outputs/models/GLM_final_upsampled.rds")

# metrics
glm_tuned_up_metrics <- final_elanet_fit_up %>%
  collect_metrics() %>% 
  mutate(model = 'GLM_tuned_upsampled')

write_xlsx(glm_tuned_up_metrics, "03_outputs/tables/appendix/glm_tuned_up_metrics.xlsx")

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

# predictions
elanet_up_preds <- final_elanet_fit_up %>%
  collect_predictions() %>% 
  select(-c(id, .config, .row))

# prepare for susceptibility mapping
glm_mapping_df <- data_test %>% 
  select(id, year, season) %>% 
  bind_cols(elanet_up_preds)

for (season_i in c("winter", "summer")) {
  
  for (year_j in c(2017, 2018)) {
    
    glm_mapping_df %>% 
      filter(season == season_i, 
             year == year_j) %>% 
      write_csv(glue("03_outputs/tables/mapping_GLM_{year_j}_{season_i}.csv"))
  }
}

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

write_xlsx(glm_tuned_down_metrics, "03_outputs/tables/appendix/glm_tuned_down_metrics.xlsx")

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
