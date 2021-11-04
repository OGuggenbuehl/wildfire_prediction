# cost matrix penalizing false negatives
cost_matrix <- tribble(
  ~truth, ~estimate, ~cost,
  "fire", "none",  2,
  "none", "fire",  1
)

# update metric with custom cost matrix
classification_cost_penalized <- metric_tweak(
  .name = "classification_cost_penalized",
  .fn = classification_cost,
  costs = cost_matrix
)



