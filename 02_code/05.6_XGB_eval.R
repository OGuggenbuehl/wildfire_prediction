xgb_fit_final_rsampl <- read_rds("03_outputs/models/XGB_final_randomsampled.rds")

# metrics
xgb_final_rsampl_metrics <- xgb_fit_final_rsampl %>%
  collect_metrics() %>% 
  mutate(model = 'XGB_down_randomsplit')

write_xlsx(xgb_final_rsampl_metrics, "03_outputs/tables/appendix/xgb_rsampl_metrics.xlsx")

# ROC curve
xgb_fit_final_rsampl %>%
  collect_predictions() %>% 
  roc_curve(fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve xgboost",
    subtitle = "downsampled, randomized split"
  )

ggsave("03_outputs/plots/roc_xgb_rsampl.png")

# confusion matrix
xgb_fit_final_rsampl %>%
  collect_predictions() %>% 
  conf_mat(truth = fire, estimate = .pred_class)

# variable importance plot
xgb_fit_final_rsampl %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "Variable Importance",
       subtitle = "xgboost, downsampled training data, randomized split")+
  theme_minimal()

ggsave("03_outputs/plots/vip_xgb_rsample.png")

# vip grid
xgb_fit_final_rsampl %>% 
  pluck(".workflow", 1) %>%   
  extract_fit_parsnip() %>% 
  vip(num_features = 15, 
      aesthetics = list(fill = "steelblue"))+
  labs(title = "XGB downsampled",
       subtitle = "randomized split")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

ggsave("03_outputs/plots/vip_grid_xgb_rsample.png", 
       width = 4, height = 4, units = 'in')
