library(tidyverse)
library(corrplot)

# load data ---------------------------------------------------------------
data <- read_rds("01_data/data_seasonal.rds") %>% 
  # drop features
  select(-c(perc_republicans,
            county_persons_per_household,
            temp_min_avg,
            temp_max_avg))

# data exploration --------------------------------------------------------
str(data)

# share of fire event 
data %>% 
  pull(fire) %>% table() %>% as_tibble() %>% 
  pivot_wider(names_from = '.', values_from = n) %>% 
  mutate(ratio = `TRUE` / `FALSE`)

data %>% 
  group_by(county) %>% 
  count(fire) %>% 
  mutate(prop = n/sum(n)) %>% 
  filter(fire) %>% 
  arrange(n)

# subset year
data %>% 
  filter(year >= 2015) %>% 
  pull(fire) %>% table() %>% as_tibble() %>% 
  pivot_wider(names_from = '.', values_from = n) %>% 
  mutate(ratio = `TRUE` / `FALSE`)

# count by seasons
data %>% 
  # filter(year >= 2015) %>% 
  group_by(season) %>% 
  count(fire) %>% 
  pivot_wider(names_from = fire,
              values_from = n) %>% 
  mutate(ratio = `TRUE` / `FALSE`)

# test for collinearity
## correlation matrix
correlation_plot <- data %>% 
  select_if(is.numeric) %>% 
  cor() %>% 
  corrplot(order = 'hclust')

# some groups of features are strongly correlated
# remove these features in preprocessing-pipeline
# most of these correlations are expected, especially the ones reporting shares
# the only real surprise is the strong negative correlation between `year` and 
# the counties' unemployment rate

# most political features are very strongly correlated
data %>% 
  select(starts_with('perc')) %>% 
  cor()

# test categorical features too by creating dummies
library(recipes)

dummies <- recipe(~., data = data) %>% 
  update_role(id, new_role = "ID") %>% 
  step_dummy(all_nominal_predictors()) %>% 
  prep() %>% 
  bake(new_data = NULL)

dummies_cor <- dummies %>% 
  select(river, lake, recreational_routes, campground,
         state_park, picnic, powerline, road, starts_with('dist')) %>% 
  cor() %>% 
  corrplot(order = 'hclust')

# as expected the dummies are quite strongly correlated with the distance measures
# distance measures are preferred for modeling, hence I drop the dummies

# inspect numeric features' distributions
distributions <- data %>% 
  select_if(is.numeric) %>% 
  pivot_longer(cols = everything(),
               names_to = 'feature', 
               values_to = 'value') %>% 
  ggplot()+
  aes(x = value)+
  geom_density()+
  facet_wrap(~feature, scales = 'free')

data %>% 
  select_if(is.numeric) %>% 
  select(starts_with('county_')) %>% 
  mutate_all(log10) %>% 
  pivot_longer(cols = everything(),
               names_to = 'feature', 
               values_to = 'value') %>% 
  ggplot()+
  aes(x = value)+
  geom_density()+
  facet_wrap(~feature, scales = 'free')

# the strongly skewed distance features can be coerced into
# more normal-like shape with a power-transformation
data %>% 
  select(starts_with('dist')) %>% 
  mutate_all(sqrt) %>%
  pivot_longer(cols = everything(),
               names_to = 'feature', 
               values_to = 'value') %>% 
  ggplot()+
  aes(x = value)+
  geom_density()+
  facet_wrap(~feature, scales = 'free')

# a ln-transformation would produce similar results, 
# but drop too many observations due to 0-values
data %>% 
  select(starts_with('dist')) %>% 
  mutate_all(log10) %>% 
  pivot_longer(cols = everything(),
               names_to = 'feature', 
               values_to = 'value') %>% 
  ggplot()+
  aes(x = value)+
  geom_density()+
  facet_wrap(~feature, scales = 'free')
