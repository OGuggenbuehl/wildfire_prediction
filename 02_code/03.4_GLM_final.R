# Upsampled ---------------------------------------------------------------

# read from disk
elanet_tune_up <- read_rds("03_outputs/GLM_tune_upsampled.rds")

# show metrics
collect_metrics(elanet_tune_up)

# select best tuning specification
best_elanet_up <- select_best(elanet_tune_up, "classification_cost_penalized")

# finalize workflow with best tuning parameters
final_elanet_wf_up <- elanet_wf_up %>% 
  finalize_workflow(best_elanet_up)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final elanet model
final_elanet_fit_up <- final_elanet_wf_up %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(final_elanet_fit_up, "03_outputs/GLM_final_upsampled.rds")

# Downsampled -------------------------------------------------------------

# read from disk
elanet_tune_down <- read_rds("03_outputs/GLM_tune_downsampled.rds")

# show metrics
collect_metrics(elanet_tune_down)

# select best tuning specification
best_elanet_down <- select_best(elanet_tune_down, "classification_cost_penalized")

# finalize workflow with best tuning parameters
final_elanet_wf_down <- elanet_wf_down %>% 
  finalize_workflow(best_elanet_down)

# register parallel-processing backend
cl <- makeCluster(all_cores)
plan(cluster, workers = cl)

# fit final elanet model
final_elanet_fit_down <- final_elanet_wf_down %>%
  last_fit(split = t_split, 
           metrics = metrics)

# shut down workers
stopCluster(cl = cl)

# write to disk
write_rds(final_elanet_fit_down, "03_outputs/GLM_final_downsampled.rds")