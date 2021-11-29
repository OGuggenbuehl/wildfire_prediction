rf_fit_final_rsampl <- read_rds("03_outputs/models/RF_final_randomsampled.rds")

# metrics
rf_final_rsampl_metrics <- rf_fit_final_rsampl %>%
  collect_metrics() %>% 
  mutate(model = 'RF_down_randomsplit')

write_xlsx(rf_final_rsampl_metrics, "03_outputs/tables/appendix/rf_rsampl_metrics.xlsx")

# ROC curve
rf_fit_final_rsampl %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve Random Forest",
    subtitle = "downsampled, randomized split"
  )

ggsave("03_outputs/plots/roc_rf_rsampl.png")

# confusion matrix
rf_fit_final_rsampl %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# variable importance plot
rf_fit_final_rsampl %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "Variable Importance, top 15 predictors",
       subtitle = "Random Forest, downsampled training data, randomized split")+
  theme_minimal()

ggsave("03_outputs/plots/vip_rf_rsample.png")

# vip grid
rf_fit_final_rsampl %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "RF downsampled",
       subtitle = "randomized split")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

ggsave("03_outputs/plots/vip_grid_rf_rsample.png", 
       width = 4, height = 4, units = 'in')
