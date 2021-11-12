library(tidyverse)
library(scales)
data_monthly <- read_rds("01_data/data_monthly.rds")
data_seasonal <- read_rds("01_data/data_seasonal.rds")

data_monthly %>% 
  filter(fire) %>% 
  group_by(month) %>% 
  summarise(n = n()) %>% 
  ggplot()+
  aes(x = month, y = n)+
  geom_col(fill = "#F73718")+
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 35, hjust = 1))+
  labs(title = 'Number of recorded wildfires in Northern California',
       subtitle = 'by month, 2010-2018',
       caption = 'Source: CAL FIRE, 2021',
       y = 'number of recorded wildfires',
       x = 'month of recording')

ggsave("03_outputs/plots/distr_monthly.png")

data_monthly %>% 
  mutate(fire = recode(as.character(fire), 
                       'TRUE' = 'fire', 
                       'FALSE' = 'none'),
         fire = fct_relevel(fire, c('fire', 'none'))) %>% 
  count(fire) %>% 
  mutate(share = n / sum(n))

data_seasonal %>% 
  mutate(fire = recode(as.character(fire), 
                       'TRUE' = 'fire', 
                       'FALSE' = 'none'),
         fire = fct_relevel(fire, c('fire', 'none'))) %>% 
  count(fire) %>% 
  mutate(share = n / sum(n)) %>% 
  ggplot()+
  aes(x = fire, y = share)+
  geom_col(fill = 'steelblue')+
  geom_label(aes(label = percent(share, accuracy = 0.1), y = 0.1))+
  theme_minimal()

ggsave("03_outputs/plots/class_imbalance.png")