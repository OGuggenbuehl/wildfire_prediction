library(tidyverse)
library(glue)
library(lubridate)
library(magrittr)
library(scales)
library(readxl)

# load data from .CSV
data <- read_csv("data/gis/data_4k_km_grid.csv") %>% 
  select(-c(left, top, right, bottom, ends_with('1912mean')))

# WorldClim ---------------------------------------------------------------

# subset to monthly precipitation data and reshape
precip <- data %>% 
  # subset
  select(id, starts_with('p') & ends_with('mean')) %>% 
  # reshape
  pivot_longer(cols = -id,
               names_to = 'date', 
               values_to = 'precip_mean') %>% 
  # extract date
  mutate(date = as_date(
    glue("20{str_sub(date, start = 2, end = 3)}-{str_sub(date, start = 4, end = 5)}-01")))

# subset to monthly minimum temperature data and reshape
tmin <- data %>% 
  # subset
  select(id, starts_with('tmin') & ends_with('me')) %>% 
  # reshape
  pivot_longer(cols = -id, names_to = 'date', values_to = 'tmin_mean') %>% 
  # extract date
  mutate(date = as_date(
    glue("20{str_sub(date, start = 5, end = 6)}-{str_sub(date, start = 7, end = 8)}-01")))

# subset to monthly maximum temperature data and reshape
tmax <- data %>% 
  # subset
  select(id, starts_with('tmax') & ends_with('me')) %>% 
  # reshape
  pivot_longer(cols = -id, names_to = 'date', values_to = 'tmax_mean') %>% 
  # extract date
  mutate(date = as_date(
    glue("20{str_sub(date, start = 5, end = 6)}-{str_sub(date, start = 7, end = 8)}-01")))

# join WorldClim data
world_clim <- precip %>% 
  left_join(tmin, by = c('id', 'date')) %>% 
  left_join(tmax, by = c('id', 'date'))

# remove intermediary data sets
rm(precip, tmax, tmin)

# drop WorldClim columns from data
data %<>% 
  select(-c(starts_with('p') & ends_with('mean'),
           starts_with('tmin') & ends_with('me'),
           starts_with('tmax') & ends_with('me')))

# Voter Registration ------------------------------------------------------

# load voter registration data
vreg <- data %>% 
  select(id, starts_with('vreg'))

# process vreg data
vreg %<>% 
  # reshape
  pivot_longer(cols = -id, 
               names_to = 'date', 
               values_to = 'registered_voters') %>% 
  # split date column
  separate(col = date, 
           into = c("year", "party"), 
           sep = "_") %>% 
  # extract date
  mutate(year = as.numeric(glue("20{str_sub(year, start = 5, end = 6)}"))) %>% 
  # reshape
  pivot_wider(names_from = party, values_from = registered_voters) %>% 
  # rename 
  rename('voter_registrations_total' = tot,
         'registered_democrats' = dem,
         'registered_republicans' = rep) %>% 
  # calculate partisan percentage
  mutate(perc_democrats = registered_democrats / voter_registrations_total,
         perc_republicans = registered_republicans / voter_registrations_total) %>% 
  select(-c(registered_democrats, registered_republicans, voter_registrations_total))

# drop Voter Registration columns from data
data %<>% 
  select(-starts_with('vreg'))

# Population Density ------------------------------------------------------

popden <- data %>% 
  select(id, starts_with('popden'))

popden %<>% 
  # reshape
  pivot_longer(cols = -id, 
               names_to = 'year', 
               values_to = 'pop_dens_mean') %>% 
  # extract year
  mutate(year = as.numeric(glue("20{str_sub(year, start = 7, end = 8)}"))) %>% 
  rename('population_density_mean' = pop_dens_mean)

# drop Population Density columns from data
data %<>% 
  select(-starts_with('popden'))

# Create Master data set --------------------------------------------------

# perform a full join with the WorldClim data to expand the data set to monthly observations
data %<>% 
  # join climate data
  full_join(world_clim, by = 'id') %>% 
  # extract year and date features
  mutate(year = year(date),
         month = month(date)) %>% 
  # reorder
  select(id, date, year, month, everything()) %>% 
  # string to date
  mutate(COMCWPPDAT = as_date(COMCWPPDAT)) %>% 
  # rename columns
  rename('community_protectplan_date' = COMCWPPDAT,
         'landcover' = WHRTYPE,
         'recreational_routes' = routes,
         'elevation_mean' = elev_mean,
         'DPA_agency' = DPA_AGENCY,
         'DPA_group' = DPA_GROUP)

# join vreg and popdens
data %<>% 
  # join Population Density data
  left_join(popden, by = c("id", "year")) %>% 
  # join Voter Registration data
  left_join(vreg, by = c("id", "year")) %>%
  # fill up voter registration data with last 2 years
  # fill(voter_registrations_total, .direction = "down") %>%
  # fill(registered_democrats, .direction = "down") %>%
  # fill(registered_republicans, .direction = "down") %>%
  fill(perc_democrats, .direction = "down") %>%
  fill(perc_republicans, .direction = "down")

rm(world_clim, popden, vreg)

# Remaining GIS data ------------------------------------------------------

# get all unique IDs
id <- data %>% 
  pull(id) %>% 
  unique()

# create sequence of all months
date <- seq.Date(from = as_date("2009-01-01"), 
                         to = as_date("2018-12-01"), 
                         by = 'month')

# cross-join data to grid of all month & ID combinations
# this is done in order to include rows for 2009 for all polygons
# these are not within the period of analysis, but are needed so that
# lagged features will not produce missing values for 2010
data %<>% 
  full_join(expand_grid(id, date), by = c("id", "date")) %>%
  arrange(id, date)

rm(id, date)

# load data
dist_city <- read_csv("data/gis/dist_city.csv") %>% 
  select(id, dist_city)

dist_firestation <- read_csv("data/gis/dist_firestation.csv") %>% 
  select(id, dist_firestation = dist_facil)

dist_lake <- read_csv("data/gis/dist_lake.csv") %>% 
  select(id, dist_lake)

dist_power <- read_csv("data/gis/dist_power.csv") %>% 
  select(id, dist_power)

dist_river <- read_csv("data/gis/dist_river.csv") %>% 
  select(id, dist_river)

dist_road <- read_csv("data/gis/dist_road.csv") %>% 
  select(id, dist_road)

fire_data <- read_csv("data/gis/fire_db_grid.csv") %>% 
  select(id, year = YEAR_, 
         alarm_date = ALARM_DATE, 
         contain_date = CONT_DATE) %>% 
  mutate(alarm_date = as_date(alarm_date),
         contain_date = as_date(contain_date),
         # impute missing containment dates
         contain_date = if_else(condition = is.na(contain_date),
                                true = alarm_date,
                                false = contain_date,
                                missing = alarm_date)) %>% 
  filter(year %in% 2009:2018) %>% 
  mutate(alarm_month = floor_date(alarm_date, unit = 'month'),
         contain_month = floor_date(contain_date, unit = 'month')) %>% 
  select(-c(alarm_date, contain_date))

# join to Master data set
data %<>% 
  # distance to nearest city 
  left_join(dist_city, by = 'id') %>% 
  # distance to nearest firestation
  left_join(dist_firestation, by = 'id') %>% 
  # distance to nearest lake
  left_join(dist_lake, by = 'id') %>% 
  # distance to nearest powerline
  left_join(dist_power, by = 'id') %>% 
  # distance to nearest river
  left_join(dist_river, by = 'id') %>% 
  # distance to nearest major road
  left_join(dist_road, by = 'id') %>% 
  # refresh year feature to join 2009 values as well
  mutate(year = year(date)) %>% 
  # fire dates
  left_join(fire_data, by = c("id", "year")) %>% 
  # create fire dummy as response
  mutate(fire = if_else(condition = date >= alarm_month & date <= contain_month,
                        true = TRUE,
                        false = FALSE, 
                        missing = FALSE)) %>% 
  # create lagged response
  group_by(id) %>% 
  mutate(fire_lag1 = lag(fire, 
                         n = 1, 
                         order_by = date),
         fire_lag2 = lag(fire, 
                         n = 2, 
                         order_by = date),
         fire_lag3 = lag(fire, 
                         n = 3, 
                         order_by = date),
         fire_lag4 = lag(fire, 
                         n = 4, 
                         order_by = date),
         fire_lag5 = lag(fire, 
                         n = 5, 
                         order_by = date),
         fire_lag6 = lag(fire, 
                         n = 6, 
                         order_by = date)) %>% 
  ungroup() %>% 
  # drop 2009 rows
  filter(year(date) != 2009) %>% 
  # reorder and drop unneeded fire dates
  select(id, date, year, month, starts_with('fire'), everything(), -c(alarm_month, contain_month))

rm(dist_city, dist_firestation, dist_lake, dist_power, dist_river, dist_road, fire_data)

# Labor Data --------------------------------------------------------------

# load labor data
labor <- read_csv("data/labor/labor data.txt") %>% 
  # subset and rename
  select(year = StartEndYear,
         month = Period,
         county = Area,
         industry = Industry, 
         n_employed = "No. of Employed") %>% 
  # filter out higher & lover industry levels
  filter(industry %in% c("Natural Resources, Mining and Constructi", 
                         "Manufacturing", "Trade, Transportation and Utilities", 
                         "Information", "Financial Activities", 
                         "Professional and Business Services", 
                         "Educational and Health Services", "Leisure and Hospitality", 
                         "Other Services", "Government")) %>% 
  # keep only county names
  mutate(county = str_replace(county, 
                              pattern = " County", 
                              replacement = "")) %>% 
  # reshape
  pivot_wider(names_from = industry, values_from = n_employed)

# Unemployment ------------------------------------------------------------

# load data
unemployment <- read_csv("data/labor/unemployment.txt") %>% 
  # subset and rename
  select(year = Year,
         month = Period,
         county = Area, 
         `Labor Force`,
         Employment,
         Unemployment,
         `Unemployment Rate`) %>% 
  # keep only county names
  mutate(county = str_replace(county, 
                              pattern = " County", 
                              replacement = ""))

# Join Labor & Unemployment Variables ------------------------------------

# create mapping table for month abbreviations
month_mapping <- tibble(month = month.abb, 
                        month_numeric = 1:12)

# load county names corresponding to polygon IDs
counties <- read_csv("data/gis/counties.csv") %>% 
  rename(county = COUNTY_NAM,
         county_abb = COUNTY_ABB,
         county_num = COUNTY_NUM,
         county_cod = COUNTY_COD,
         county_fip = COUNTY_FIP)

# join data sets
data %<>% 
  # rename
  rename(month_numeric = month) %>% 
  # join month names
  left_join(month_mapping, by = "month_numeric") %>% 
  # join county names
  left_join(counties[,1:2], by = "id") %>% 
  # koin labor data
  left_join(labor, by = c("year", "month", "county")) %>% 
  # join unemployment data
  left_join(unemployment, by = c("year", "month", "county")) %>% 
  # reorder features
  select(id, date, year, month, county, everything()) %>% 
  # rename features
  rename("employ_natresources_mining_construction" = "Natural Resources, Mining and Constructi",
         "employ_manufacturing" = "Manufacturing",
         "employ_trade_transport_utilities" = "Trade, Transportation and Utilities",
         "employ_IT" = "Information",
         "employ_financial" = "Financial Activities",
         "employ_professional_business" = "Professional and Business Services",
         "employ_educational_health" = "Educational and Health Services",
         "employ_leisure_hospitality" = "Leisure and Hospitality",
         "employ_other_services" = "Other Services",
         "employ_government" = "Government",
         "county_laborforce" = "Labor Force",
         "county_employment" = "Employment",
         "county_unemployment" = "Unemployment",
         "county_unemployment_rate" = "Unemployment Rate")

# remove unneeded data sets
rm(labor, unemployment)

# Ballot Measures ---------------------------------------------------------

# load ballot measures data
ballot_measures_2010 <- read_csv2("data/ballot measures CA/2010-ballot-measures-summary.csv")
ballot_measures_2016 <- read_csv2("data/ballot measures CA/2016-ballot-measures.csv")

# stack data sets
ballot_measures <- bind_rows(ballot_measures_2010, ballot_measures_2016) %>% 
  # rename features
  rename("county" = County,
         "proposition" = Proposition,
         "yes_votes" = Yes,
         "no_votes" = No) %>% 
  # process data
  mutate(proposition = glue("prop{word(proposition, 2)}"),
         yes_votes = as.numeric(yes_votes),
         no_votes = as.numeric(no_votes),
         total_votes = yes_votes + no_votes,
         perc_yes = yes_votes / total_votes) %>% 
  # subset
  select(county, proposition, perc_yes) %>% 
  # reshape
  pivot_wider(names_from = proposition, 
              values_from = perc_yes, names_prefix = 'perc_yes_')

# join to master data set
data %<>% 
  left_join(ballot_measures, by = "county")

# remove unneeded data sets
rm(ballot_measures, ballot_measures_2010, ballot_measures_2016)

# Demographic data --------------------------------------------------------

# get all unique County names
counties_uniq <- counties %>% 
  pull(county) %>% 
  unique()

# load separate excel sheets as list elements
demo_list <- list()

# load all excel sheets as list elements
for (year in 2009:2018) {
  
  # choose different path for 2009 file
  if (year == 2009) {
    
    df <- read_xls("data/population/E8_2000-2010_Report_ByYear_Final_EOC.xls",
             sheet = "2009 County State",
             skip = 3) %>%
      # subset and rename
      select(county = County,
             population = "Total...2",
             vacancy_rate = "Vacancy Rate",
             persons_per_household = "Persons Per Household") %>%
      # filter out unused counties
      filter(county %in% counties_uniq) %>% 
      # add identifier for processed year
      mutate(year = year)
    
  } else {
    
    df <- read_xlsx("data/population/E-5_2021_InternetVersion.xlsx", 
                    sheet = glue("E5CountyState{year}"), 
                    skip = 2) %>% 
      # subset and rename
      select(county = County,
             population = "Total",
             vacancy_rate = "Vacancy Rate",
             persons_per_household = "Persons per Household") %>% 
      # filter out unused counties
      filter(county %in% counties_uniq) %>% 
      # add identifier for processed year
      mutate(year = year)
    
  }
  
  # save as list element
  demo_list[[as.character(year)]] <- df
  # remove intermediary object
  rm(df)
}

# combine list elements to tibble
demographics <- demo_list %>% 
  # stack all list elements to tibble
  bind_rows() %>% 
  # reorder
  select(county, year, everything()) %>% 
  # arrange by county & year
  arrange(county, year)

rm(demo_list)

# clean and process demographic data
demographics %<>% 
  # create lagged population to calculate population growth
  group_by(county) %>% 
  mutate(pop_lag = lag(population, 
                       n = 1),
         pop_growth = (population - pop_lag) / pop_lag) %>% 
  ungroup() %>% 
  # remove unneeded 2009 data
  filter(year != 2009) %>% 
  # subset and rename
  select(county, 
         year, 
         # county_pop = population, 
         county_pop_growth = pop_growth, 
         county_vacancy_rate = vacancy_rate, 
         county_persons_per_household = persons_per_household)

# join to master data set
data %<>% 
  left_join(demographics, by = c("year", "county")) %>% 
  mutate(month = as_factor(month))

# remove unneeded data sets
rm(demographics)

# Inspect Data ------------------------------------------------------------

# check for missing values in feature space
data %>% 
  sapply(function(x) sum(is.na(x))) %>% 
  data.frame() %>% 
  rownames_to_column() %>% 
  rename(feature = "rowname", 
         n_NA = ".") %>% 
  mutate(na_ratio = round(n_NA/ nrow(data), digits = 2))

# take a closer look at the missing labor data
data %>% 
  select(county, starts_with('employ_')) %>% 
  pivot_longer(cols = -county, names_to = 'industry', values_to = 'employed') %>% 
  group_by(county, industry) %>% 
  summarise(n_na = sum(is.na(employed))) %>% 
  arrange(desc(n_na)) 

# plot population density on log10-scale
data %>% 
  ggplot()+
  aes(x = population_density_mean)+
  geom_histogram()+
  scale_y_log10()

# missing labor data are actually implicit zeroes
# as they only appear in the most sparsely populated
# counties where almost no local business exists

# population density are also implicit zeroes
# as uninhabited areas are excluded

# imputation
data %<>% 
  # replace NAs with 0 for labor statistics
  mutate_at(vars(starts_with("employ")), 
            replace_na, 
            replace = 0) %>% 
  # replace NAs with 0 for population density
  mutate(population_density_mean = replace_na(population_density_mean, 0)) %>% 
  # compute industry employees as shares of laborforce
  mutate_at(.vars = vars(starts_with('employ_')), 
            .funs = ~./county_laborforce) %>% 
  # rename features
  rename_at(.vars = vars(starts_with('employ_')), 
            .funs = ~glue("share_{str_replace(., 'employ_', '')}")) %>% 
  # drop unneeded features
  select(-c(county_laborforce, county_employment, county_unemployment))

# final NA check
data %>% 
  sapply(function(x) sum(is.na(x)))

# Feature Engineering -----------------------------------------------------

data %<>% 
  # community_protectplan year mapping
  mutate(community_protect_plan = if_else(condition = date >= community_protectplan_date, 
                                             true = TRUE, 
                                             false = FALSE, 
                                             missing = FALSE)) %>% 
  # FFSC year mapping 
  mutate(FFSC = if_else(condition = year >= FFSC_year, 
                        true = FFSC, 
                        false = 'none', 
                        missing = 'none')) %>% 
  # CCED year mapping
  mutate(CCED = if_else(condition = date >= CCED_date,
                        true = CCED,
                        false = FALSE,
                        missing = FALSE)) %>% 
  # add seasons
  mutate(season = if_else(condition = month %in% month.abb[5:10], 
                          true = 'summer', 
                          false = 'winter')) %>% 
  # recode id to string
  mutate(id = as.character(id)) %>% 
  # rename for clarity
  rename(landcover_majority = landcover,
         temp_min_avg = tmin_mean,
         temp_max_avg = tmax_mean,
         date_floored = date) %>% 
  # drop unneeded features
  select(-c(community_protectplan_date, 
            FFSC_year, 
            CCED_date, 
            month_numeric,
            date_floored)) %>% 
  # drop unneeded observations
  filter(!id %in% c("841", "1318", "4092", "4115", "4138", "4161", "4184", 
                    "4207", "6186", "6370", "6393", "6416"))

# write final tibble to disk
write_rds(data, "data/data_final.rds")