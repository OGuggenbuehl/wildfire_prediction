rf_fit_final_down <- read_rds("03_outputs/models/RF_final_randomsampled.rds")

# metrics
rf_tuned_down_metrics <- rf_fit_final_down %>%
  collect_metrics() %>% 
  mutate(model = 'RF_down_randomsplit')

# ROC curve
rf_fit_final_down %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
rf_fit_final_down %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# variable importance plot
rf_fit_final_down %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "Variable Importance, top 15 predictors",
       subtitle = "Random Forest, downsampled training data, randomized split")+
  theme_minimal()

ggsave("03_outputs/plots/vip_rf_rsample.png")
