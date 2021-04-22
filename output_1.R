
pacman::p_load(tidyverse, scales, gt, here)

source(file = here("script/functions.R"))

# set output

output <- here("output")

# import data 

distance_data <- read_csv("data/processed/distance_processed.csv")

# import band summary stats 

summary_stats <- read_csv("data/processed/band_summary_stats.csv") 

# import band count data

band_reserve_count <- read_csv("data/processed/band_reserve_count.csv")

# import ferry routes

ferry_routes <- read_csv("data/processed/ferry_routes.csv")

#################################################

###### table 2 ############

# total number of band offices

n_band_office <- round(nrow(summary_stats),0)

# band offices located on a reserve csd

office_on_reserve <- summary_stats %>% 
  filter(office_reserve  == "reserve csd") %>% 
  nrow()

# band offices with census pop avail
data_missing <- summary_stats %>% 
  filter(is.na(pop_16)) %>% 
  distinct(csdname) %>% 
  nrow()

data_avail <-  n_band_office - data_missing

# band offices on a single reserve
single_reserve_association <- band_reserve_count %>% 
  mutate(count_reserves = ifelse(is.na(count_reserves), manual_search_count, count_reserves)) %>% 
  mutate(lone_reserve = ifelse(count_reserves == 1, 1, 0)) %>% 
  mutate(lone_reserve = ifelse(is.na(lone_reserve), 1, lone_reserve)) %>% 
  filter(lone_reserve == 1) %>%
  nrow()

# band offices within 20 km of a population centre
percent_within_20 <- summary_stats %>% 
  filter(pop_center_distance < 20) %>% 
  nrow()

table_2 <- tribble(
  ~band_office_variable, ~value,
  "Number of First Nations band offices in Canada", n_band_office,
  "Band offices located on a reserve", office_on_reserve,
  "Band offices with census population data available", data_avail,
  "Band offices associated with a single reserve", single_reserve_association,
  "Band offices within 20 km of a population centre", percent_within_20)

table_2 %>% 
  gt() %>% 
  gtsave("tbl_2.html", inline_css = TRUE, path = output)
  
########################################################

# table 3

# count missing API from nearest distance

# travel NA impute with nw

travel_missing <- distance_data %>%
  filter(is.na(travel_na_wo_nw)) %>% 
  nrow()

# count ferry routes
n_ferry_routes <- ferry_routes %>% 
  filter(ferry_route == 1) %>% 
  nrow() 

# id road routes 

id_road_routes <- n_band_office - travel_missing - n_ferry_routes

# top coded road routes

n_top_coded <- distance_data %>% 
  filter(travel_wo_nw == 500) %>% 
  nrow()

# n imputed 

n_imputed <- travel_missing - n_top_coded

table_3 <- tribble(
  ~travel_stat, ~value,
  "Number of travel routes between band offices to closest cash sources", n_band_office,
  "API-identified road routes", id_road_routes,
  "Road route proxied by geographical distance (within 20 kms)", n_imputed,
  "Travel route top-coded at 500 kms", n_top_coded,
  "API-identified routes involving a ferry trip", n_ferry_routes)

table_3 %>%
  gt() %>% 
  gtsave(
    "tbl_3.html", inline_css = TRUE, path = output)

#########################################
# table 4
distance_data %>% 
  #select(geo_w_nw, geo_wo_nw, travel_w_nw, travel_wo_nw) %>% 
  select(geo_wo_nw, travel_wo_nw) %>% 
  summarise(across(everything(), list(mean = mean, median = median), .names = "{fn}_{col}")) %>% 
  pivot_longer(cols = starts_with(c("mean", "median")), names_to = "statistic") %>% 
  separate(statistic, into = c('statistic', 'colnm'), sep="_", 
           extra = 'merge') %>% 
  mutate(colnm = str_replace(colnm, '_wo_nw', '_distance')) %>%
  pivot_wider(names_from = colnm, values_from = value) %>% 
  arrange(desc(statistic)) %>%
  mutate(geo_distance = round(geo_distance, 1)) %>% 
  mutate(travel_distance = round(travel_distance, 1)) %>% 
  gt() %>% 
  gtsave(
    "tbl_4.html", inline_css = TRUE, path = output)

# table 5
distance_data %>% 
  select(geo_wl_atm, geo_fi_atm, geo_branch, travel_branch_500, travel_fi_atm_500, travel_wl_atm_500) %>% 
  summarise(across(everything(), list(mean = mean, median = median), .names = "{fn}_{col}")) %>% 
  pivot_longer(cols = starts_with(c("mean", "median")), names_to = "statistic") %>% 
  separate(statistic, into = c('statistic', 'colnm'), sep="_", 
           extra = 'merge') %>% 
  mutate(colnm = str_replace(colnm, '_atm', '')) %>%
  mutate(colnm = str_replace(colnm, '_500', '')) %>% 
  separate(colnm, into = c('measure', 'cash_source'), sep="_", 
           extra = 'merge') %>% 
  pivot_wider(names_from = cash_source, values_from = value) %>%
  select(statistic, measure, branch, fi, wl) %>% 
  mutate(across(c(branch:wl), round, 1)) %>% 
  arrange(desc(statistic), measure) %>%
  gt() %>% 
  gtsave(
    "tbl_5.html", inline_css = TRUE, path = output)

# table 6

imap_dfr(lst(1, 5, 10, 20, 50, 100, 400), ~ {
  ul <- .x
  distance_data %>%
    select(geo_wo_nw, geo_w_nw, travel_wo_nw, travel_w_nw) %>% 
    summarise(across(everything(),
                     ~ mean(between(., 0, ul))))}, .id = 'within') %>%
  mutate(across(c(geo_wo_nw:travel_w_nw),  ~ . * 100)) %>% 
  mutate(across(c(geo_wo_nw:travel_w_nw), round, 2)) %>% 
  gt() %>% 
  gtsave("tbl_6.html", inline_css = TRUE, path = output)

# appendix 2

summary_stats %>% 
  inner_join(distance_data) %>% 
  filter(travel_wo_nw == 500) %>% 
  select(-travel_wo_nw) %>% 
  mutate(pop_16 = ifelse(row_id == 534, 88, pop_16)) %>% 
  arrange(prname, band_name) %>% 
  select(row_id, band_name, prname, csdname, 
         pop_16, pop_center_distance, geo_wo_nw) %>%
  mutate(across(c(pop_center_distance:geo_wo_nw), round, 2)) %>% 
  rename(geodistance = geo_wo_nw) %>% 
  gt() %>% 
  gtsave("appendix_2.html", inline_css = TRUE, path = output)

# appendix 3
summary_stats %>% 
  inner_join(ferry_routes) %>% 
  inner_join(distance_data) %>% 
  filter(ferry_route == 1) %>% 
  arrange(prname, band_name) %>% 
  select(row_id, band_name, prname, csdname, 
         pop_16, pop_center_distance, geo_wo_nw, travel_wo_nw) %>%
  mutate(across(c(pop_center_distance:travel_wo_nw), round, 1)) %>% 
  arrange(row_id) %>% 
  gt() %>% 
  gtsave("appendix_3.html", inline_css = TRUE, path = output)
  
  