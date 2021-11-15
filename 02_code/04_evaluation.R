library(tidyverse)
library(tidymodels)

# read from disk
data_train <- read_rds("01_data/data_train.rds")
data_test <- read_rds("01_data/data_test.rds")

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