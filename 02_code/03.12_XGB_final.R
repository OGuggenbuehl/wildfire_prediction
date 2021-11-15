# Upsampled ---------------------------------------------------------------

# read from disk
xgb_tune_up <- read_rds("03_outputs/XGB_tuned_upsampled.rds")

# show metrics
collect_metrics(xgb_tune_up) %>% 
  select(-c(n, std_err, .config)) %>% 
  pivot_wider(names_from = .metric, values_from = mean)

# select best tuning specification
best_xgb_up <- select_best(xgb_tune_up, "classification_cost_penalized")

# finalize workflow with best tuning parameters
best_xgb_wf_up <- xgb_workflow_up %>% 
  finalize_workflow(best_xgb_up)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final RF model
xgb_fit_final_up <- best_xgb_wf_up %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(xgb_fit_final_up, "03_outputs/XGB_final_upsampled.rds")

# Downsampled -------------------------------------------------------------

# read from disk
xgb_tune_down <- read_rds("03_outputs/XGB_tuned_downsampled.rds")

# show metrics
collect_metrics(xgb_tune_down) %>% 
  select(-c(n, std_err, .config)) %>% 
  pivot_wider(names_from = .metric, values_from = mean)

# select best tuning specification
best_xgb_down <- select_best(xgb_tune_down, "classification_cost_penalized")

# finalize workflow with best tuning parameters
best_xgb_wf_down <- xgb_workflow_down %>% 
  finalize_workflow(best_xgb_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final model
xgb_fit_final_down <- best_xgb_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(xgb_fit_final_down, "03_outputs/XGB_final_downsampled.rds")