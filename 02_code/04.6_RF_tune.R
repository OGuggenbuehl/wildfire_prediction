# Upsampled ---------------------------------------------------------------

# read from disk
rf_fit_final_up <- read_rds("03_outputs/models/RF_final_upsampled.rds")

# metrics
rf_tuned_up_metrics <- rf_fit_final_up %>%
  collect_metrics() %>% 
  mutate(model = 'RF_tuned_upsampled')

write_xlsx(rf_tuned_up_metrics, "03_outputs/tables/appendix/rf_tuned_up_metrics.xlsx")

# ROC curve
rf_fit_final_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve Random Forest",
    subtitle = "upsampled, temporal split (2016)"
  )

ggsave("03_outputs/plots/roc_rf_up_time.png")

# confusion matrix
rf_fit_final_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# variable importance plot
rf_fit_final_up %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "Variable Importance",
       subtitle = "Random Forest, upsampled training data, temporal split (2016)")+
  theme_minimal()

ggsave("03_outputs/plots/vip_rf_up_time.png")

# Downsampled -------------------------------------------------------------

# read from disk
rf_fit_final_down <- read_rds("03_outputs/models/RF_final_downsampled.rds")

# metrics
rf_tuned_down_metrics <- rf_fit_final_down %>%
  collect_metrics() %>% 
  mutate(model = 'RF_tuned_downsampled')

write_xlsx(rf_tuned_down_metrics, "03_outputs/tables/appendix/rf_tuned_down_metrics.xlsx")

# ROC curve
rf_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve Random Forest",
    subtitle = "downsampled, temporal split (2016)"
  )

ggsave("03_outputs/plots/roc_rf_down_time.png")

# predictions
rf_down_preds <- rf_fit_final_down %>%
  collect_predictions() %>% 
  select(-c(id, .config, .row))

# prepare for susceptibility mapping
rf_mapping_df <- data_test %>% 
  select(id, year, season) %>% 
  bind_cols(rf_down_preds)

for (season_i in c("winter", "summer")) {
  
  for (year_j in c(2017, 2018)) {
    
    rf_mapping_df %>% 
      filter(season == season_i, 
             year == year_j) %>% 
      write_csv(glue("03_outputs/tables/mapping_RF_{year_j}_{season_i}.csv"))
  }
}

# confusion matrix
rf_down_preds %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# variable importance plot
rf_fit_final_down %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "Variable Importance",
       subtitle = "Random Forest, downsampled training data, temporal split (2016)")+
  theme_minimal()

ggsave("03_outputs/plots/vip_rf_down_time.png")

# vip grid
rf_fit_final_down %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "RF downsampled",
       subtitle = "temporal split")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

ggsave("03_outputs/plots/vip_grid_rf_down_time.png", 
       width = 4, height = 4, units = 'in')
