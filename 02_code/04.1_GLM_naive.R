# read from disk
glm_naive <- read_rds("03_outputs/GLM_naive.rds")

# predictions
glm_naive_preds <- predict(glm_naive, type = 'prob',
                           new_data = data_test) %>% 
  bind_cols(data_test)

# plot ROC curve
glm_naive_preds %>% 
  roc_curve(truth = fire, .pred_fire) %>% 
  autoplot()

# confusion matrix
glm_confmat <- predict(glm_naive, type = 'class',
                       new_data = data_test) %>% 
  bind_cols(data_test) %>% 
  conf_mat(truth = fire, 
           estimate = .pred_class)
glm_confmat

# metrics 
glm_naive_metrics <- summary(glm_confmat) %>% 
  bind_rows(classification_cost_penalized(truth = fire, 
                                          .pred_fire, 
                                          data = glm_naive_preds)) %>% 
  mutate(model = 'GLM_naive') %>% 
  select(-.estimator)
