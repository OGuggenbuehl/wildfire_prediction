library(stacks)

# create stack
model_stack <- stacks() %>%
  # add candidate models
  add_candidates(glm_tune) %>%
  add_candidates(rf_tune) %>%
  add_candidates(xgb_tune)

model_stack

# fit stack
model_stack_fit <-
  model_stack %>%
  # determine optimal candidate combination
  blend_predictions() %>% 
  # fit accordingly 
  fit_members()

# save predictions
stack_preds <- model_stack_fit %>% 
  # predict with stack
  predict(new_data = data_test) %>% 
  # bind predictions to testing data
  bind_cols(data_test)