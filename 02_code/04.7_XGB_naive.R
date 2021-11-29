# read from disk
xgb_fit <- read_rds("03_outputs/models/XGB_naive.rds")

# predictions
xgb_naive_preds <- predict(xgb_fit, type = 'prob',
                           new_data = data_test) %>% 
  bind_cols(data_test)

# plot ROC curve
xgb_naive_preds %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve xgboost",
    subtitle = "naïve estimation, temporal split (2016)"
  )

ggsave("03_outputs/plots/appendix/roc_xgb_naive.png")

# confusion matrix
xgb_confmat <- predict(xgb_fit, type = 'class',
                       new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
xgb_confmat

# metrics 
xgb_naive_metrics <- summary(xgb_confmat) %>% 
  bind_rows(roc_auc(truth = fire, 
                    .pred_fire, 
                    data = xgb_naive_preds)) %>% 
  bind_rows(classification_cost_penalized(truth = fire, 
                                          .pred_fire, 
                                          data = xgb_naive_preds)) %>% 
  mutate(model = 'XGB_naive') %>% 
  select(-.estimator) %>% 
  filter(.metric %in% my_metrics)

write_xlsx(xgb_naive_metrics, "03_outputs/tables/appendix/xgb_naive_metrics.xlsx")
