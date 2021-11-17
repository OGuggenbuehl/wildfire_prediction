library(tidyverse)
library(tidymodels)

# read from disk
data_train <- read_rds("01_data/data_train.rds")
data_test <- read_rds("01_data/data_test.rds")

my_metrics <- c("classification_cost_penalized",
                "f_meas", "precision", "recall",
                "sensitivity", "specificity",
                "accuracy", "roc_auc")

# load custom classification metric
source("02_code/custom_cost_matrix.R")

# GLM ---------------------------------------------------------------------
# naive estimation
source("02_code/04.1_GLM_naive.R", echo = TRUE)
# resampled
source("02_code/04.2_GLM_res.R", echo = TRUE)
# tuned elastic net
source("02_code/04.3_GLM_tune.R", echo = TRUE)

# Random Forest -----------------------------------------------------------
# naive estimation
source("02_code/04.4_RF_naive.R", echo = TRUE)
# resampled
source("02_code/04.5_RF_res.R", echo = TRUE)
# tuned
source("02_code/04.6_RF_tune.R", echo = TRUE)

# XGB ---------------------------------------------------------------------
# naive
source("02_code/04.7_XGB_naive.R", echo = TRUE)
# resampled
source("02_code/04.8_XGB_res.R", echo = TRUE)
# tune
source("02_code/04.9_XGB_tune.R", echo = TRUE)

# Stacking ----------------------------------------------------------------
source("02_code/04.10_stacking.R", echo = TRUE)

# create table for comparing metrics
model_comp <- glm_res_up_metrics %>% 
  bind_rows(glm_res_down_metrics) %>% 
  bind_rows(glm_tuned_up_metrics) %>% 
  bind_rows(glm_tuned_down_metrics) %>% 
  bind_rows(rf_res_up_metrics) %>% 
  bind_rows(rf_res_down_metrics) %>% 
  bind_rows(rf_tuned_up_metrics) %>% 
  bind_rows(rf_tuned_down_metrics) %>%
  bind_rows(xgb_res_up_metrics) %>% 
  bind_rows(xgb_res_down_metrics) %>% 
  bind_rows(xgb_tuned_up_metrics) %>% 
  bind_rows(xgb_tuned_down_metrics) %>% 
  mutate(.estimate = if_else(is.na(.estimate), 
                             true = mean, 
                             false = .estimate)) %>% 
  select(.metric, .estimate, model) %>% 
  bind_rows(glm_naive_metrics) %>% 
  bind_rows(rf_naive_metrics) %>% 
  bind_rows(xgb_naive_metrics) %>% 
  filter(.metric %in% my_metrics) %>% 
  arrange(model, .metric) %>% 
  pivot_wider(names_from = model, values_from = .estimate)

# create separate objects for model metrics to save as list elements
models_naive <- model_comp %>% 
  select(.metric, dplyr::contains("naive"))
models_res <- model_comp %>% 
  select(.metric, dplyr::contains("res"))
models_tuned <- model_comp %>% 
  select(.metric, dplyr::contains("tune"))

model_comp_list <- list('naive' = models_naive,
                        'resampled' = models_res,
                        'tuned' = models_tuned)

# write to disk
write_rds(model_comp_list, "03_outputs/tables/model_comp.rds")
# read from disk
model_comp_list <- read_rds("03_outputs/tables/model_comp.rds")

# write to disk for .docx import
write.table(model_comp_list$naive, file = "03_outputs/tables/model_comp_naive.txt", 
            sep = ",", quote = FALSE, row.names = FALSE)
write.table(model_comp_list$resampled, file = "03_outputs/tables/model_comp_res.txt", 
            sep = ",", quote = FALSE, row.names = FALSE)
write.table(model_comp_list$tuned, file = "03_outputs/tables/model_comp_tuned.txt", 
            sep = ",", quote = FALSE, row.names = FALSE)
