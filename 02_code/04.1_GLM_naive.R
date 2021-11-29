# read from disk
glm_naive <- read_rds("03_outputs/models/GLM_naive.rds")

broom::tidy(glm_naive) %>% 
  write_xlsx("03_outputs/tables/appendix/reg_glm_naive.xlsx")

# predictions
glm_naive_preds <- predict(glm_naive, type = 'prob',
                           new_data = data_test) %>% 
  bind_cols(data_test)

# plot ROC curve
glm_naive_preds %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()+
  theme_minimal()+
  labs(
    title = "ROC-curve logistic regression",
    subtitle = "naïve estimation, temporal split (2016)"
  )

ggsave("03_outputs/plots/appendix/roc_glm_naive.png")

# confusion matrix
glm_confmat <- predict(glm_naive, type = 'class',
                       new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
glm_confmat

# metrics 
glm_naive_metrics <- summary(glm_confmat) %>% 
  bind_rows(roc_auc(truth = fire, 
                    .pred_fire, 
                    data = glm_naive_preds)) %>% 
  bind_rows(classification_cost_penalized(truth = fire, 
                                          .pred_fire, 
                                          data = glm_naive_preds)) %>% 
  mutate(model = 'GLM_naive') %>% 
  select(-.estimator) %>% 
  filter(.metric %in% my_metrics)

write_xlsx(glm_naive_metrics, "03_outputs/tables/appendix/glm_naive_metrics.xlsx")
