# specify model
glm_model <- logistic_reg() %>% 
  set_engine("glm") %>% 
  set_mode("classification")

# preprocessing recipe
glm_recipe <-  recipe(fire ~ ., data = data_train) %>% 
  # remove id from predictors
  update_role(id, new_role = "ID") %>% 
  # drop highly correlated features
  step_rm(lake, river, powerline, road,
          recreational_routes, starts_with('perc_yes')) %>%
  # turn all categorical features into dummy variables
  step_dummy(all_nominal_predictors()) %>%
  # upsampling with SMOTE
  step_smote(fire, 
             # skip for test set
             skip = TRUE) %>%
  # power transformation for skewed distance features
  step_sqrt(starts_with('dist_')) %>% 
  # remove 0-variance features
  step_zv(all_predictors()) %>%
  # remove highly-correlated features
  step_corr(all_numeric_predictors(),
            threshold = .9)

# bundle model and recipe to workflow
glm_workflow <- workflow() %>% 
  add_model(glm_model) %>% 
  add_recipe(glm_recipe)

# register parallel-processing backend
registerDoParallel(cl)

# fit model
start <- Sys.time()
glm_fit <- glm_workflow %>% 
  fit_resamples(resamples = cv_splits, 
                metrics = metrics, 
                control = control_resamples(
                  verbose = TRUE,
                  save_pred = TRUE,
                  event_level = "second", 
                  allow_par = TRUE, 
                  parallel_over = 'resamples')
  )
end <- Sys.time()
end-start

# write_rds(glm_fit, "03_outputs/glm_fit.rds")
# glm_fit <- read_rds("03_outputs/glm_fit.rds")

# metrics of resampled fit
collect_metrics(glm_fit)

# summarize within-fold predictions
glm_preds <- collect_predictions(glm_fit, 
                                 summarize = TRUE)

# plot ROC curve
glm_preds %>% 
  roc_curve(truth = fire, .pred_FALSE) %>% 
  autoplot()

# confusion matrix
glm_confmat <- glm_preds %>% 
  conf_mat(truth = fire, estimate = .pred_class)
glm_confmat

# additional metrics 
summary(glm_confmat, 
        event_level = 'second')