# Upsampling --------------------------------------------------------------

# read from disk
xgb_fit_final_up <- read_rds("03_outputs/models/XGB_final_upsampled.rds")

# metrics
xgb_tuned_up_metrics <- xgb_fit_final_up %>%
  collect_metrics() %>% 
  mutate(model = 'XGB_tuned_upsampled')

write_xlsx(xgb_tuned_up_metrics, "03_outputs/tables/appendix/xgb_tuned_up_metrics.xlsx")

# ROC curve
xgb_fit_final_up %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve xgboost",
    subtitle = "upsampled, temporal split (2016)"
  )

ggsave("03_outputs/plots/roc_xgb_up_time.png")

# confusion matrix
xgb_fit_final_up %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# variable importance plot
xgb_fit_final_up %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "Variable Importance",
       subtitle = "xgboost, upsampled training data, temporal split (2016)")+
  theme_minimal()

ggsave("03_outputs/plots/vip_xgb_up_time.png")

# Downsampling ------------------------------------------------------------

# read from disk
xgb_fit_final_down <- read_rds("03_outputs/models/XGB_final_downsampled.rds")

# metrics
xgb_tuned_down_metrics <- xgb_fit_final_down %>%
  collect_metrics() %>% 
  mutate(model = 'XGB_tuned_downsampled')

write_xlsx(xgb_tuned_down_metrics, "03_outputs/tables/appendix/xgb_tuned_down_metrics.xlsx")

# ROC curve
xgb_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve xgboost",
    subtitle = "downsampled, temporal split (2016)"
  )

ggsave("03_outputs/plots/roc_xgb_down_time.png")

# predictions
xgb_down_preds <- xgb_fit_final_down %>%
  collect_predictions() %>% 
  select(-c(id, .config, .row))

# prepare for susceptibility mapping
xgb_mapping_df <- data_test %>% 
  select(id, year, season) %>% 
  bind_cols(xgb_down_preds)

for (season_i in c("winter", "summer")) {
  
  for (year_j in c(2017, 2018)) {
    
    xgb_mapping_df %>% 
      filter(season == season_i, 
             year == year_j) %>% 
      write_csv(glue("03_outputs/tables/mapping_XGB_{year_j}_{season_i}.csv"))
  }
}

# confusion matrix
xgb_fit_final_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# variable importance plot
xgb_fit_final_down %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "Variable Importance",
       subtitle = "xgboost, downsampled training data, temporal split (2016)")+
  theme_minimal()

ggsave("03_outputs/plots/vip_xgb_down_time.png")

# vip grid
xgb_fit_final_down %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "XGB downsampled",
       subtitle = "temporal split")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

ggsave("03_outputs/plots/vip_grid_xgb_down_time.png", 
       width = 4, height = 4, units = 'in')
