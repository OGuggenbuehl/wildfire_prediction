# Upsampled ---------------------------------------------------------------

# read from disk
rf_tune_up <- read_rds("03_outputs/RF_tuned_upsampled.rds")

# show metrics
collect_metrics(rf_tune_up)

# select best tuning specification
best_rf_up <- select_best(rf_tune_up, "roc_auc")

# finalize workflow with best tuning parameters
best_rf_wf_up <- rf_workflow_up %>% 
  finalize_workflow(best_rf_up)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final RF model
rf_fit_final_up <- best_rf_wf_up %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(rf_fit_final_up, "03_outputs/RF_final_upsampled.rds")

# Downsampled -------------------------------------------------------------
# read from disk
rf_tune_down <- read_rds("03_outputs/RF_tuned_downsampled.rds")

# show metrics
collect_metrics(rf_tune_down)

# select best tuning specification
best_rf_down <- select_best(rf_tune_down, "roc_auc")

# finalize workflow with best tuning parameters
best_rf_wf_down <- rf_workflow_down %>% 
  finalize_workflow(best_rf_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final RF model
rf_fit_final_down <- best_rf_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(rf_fit_final_down, "03_outputs/RF_final_downsampled.rds")