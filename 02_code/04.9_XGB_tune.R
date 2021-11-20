# Upsampling --------------------------------------------------------------

# read from disk
xgb_fit_final_up <- read_rds("03_outputs/models/XGB_final_upsampled.rds")

# metrics
xgb_tuned_up_metrics <- xgb_fit_final_up %>%
  collect_metrics() %>% 
  mutate(model = 'XGB_tuned_upsampled')

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
