# create custom metric penalizing false negatives 
classification_cost_penalized <- function(
  data,
  truth,
  class_prob,
  na_rm = TRUE
) {
  
  # cost matrix penalizing false negatives
  cost_matrix <- tribble(
    ~truth, ~estimate, ~cost,
    "fire", "none",  2,
    "none", "fire",  1
  )
  
  classification_cost(
    data = data,
    truth = !! rlang::enquo(truth),
    # supply the function with the class probabilities
    !! rlang::enquo(class_prob), 
    # supply the function with the cost matrix
    costs = cost_matrix,
    na_rm = na_rm
  )
}

# Use `new_numeric_metric()` to formalize this new metric function
classification_cost_penalized <- new_prob_metric(classification_cost_penalized, "minimize")

xgb_fit_final_down %>% 
  collect_predictions() %>% 
  classification_cost_penalized(truth = fire, class_prob = .pred_fire)

