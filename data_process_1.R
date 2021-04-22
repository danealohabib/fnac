# load and install packages
if (!require("pacman")) install.packages("pacman")

# import packages
pacman::p_load(tidyverse, janitor, data.table, here)

# locate files census files

files_names <- list.files("data/unprocessed/csd_census/", recursive = TRUE, full.names = TRUE, pattern = "^98.*\\.csv")

# Source functions
source(file = here("script/functions.R"))

# clean and select census data for all provinces
# pull population for 
data <- files_names %>%
  map_df(~ fread(.x)) %>%
  clean_names() %>%
  select(
    year = "census_year",
    geo_name,
    csd_type_name,
    variable = "dim_profile_of_census_subdivisions_2247",
    measure = "dim_sex_3_member_id_1_total_sex"
  ) %>%
  # pull population variable
  mutate(variable = str_to_lower(variable)) %>%
  filter(variable %in% c(
    "population, 2016"
  )) %>%
  # flag all reserve CSDs
  mutate(
    #office_reserve_1 = ifelse(csd_type_name %in% reserve_csds, 1, 0),
    office_reserve = ifelse(csd_type_name %in% reserve_csds, "reserve csd", "other csd")
  ) %>%
  # clean population variable
  group_by(year, geo_name, variable, csd_type_name) %>%
  mutate(rn = row_number()) %>%
  pivot_wider(names_from = variable, values_from = measure) %>%
  filter_at(3:ncol(.), all_vars(!is.na(.))) %>%
  ungroup() %>%
  select(-rn) %>%
  na_if("x") %>%
  na_if("F") %>%
  clean_names() %>%
  rename(
    csd_name = "geo_name"
  ) %>%
  mutate(
    population_2016 = as.double(population_2016)) %>% 
  select(
    csdname = csd_name,
    pop_16 = population_2016,
    office_reserve
  ) %>%
  group_by(csdname) %>%
  slice_max(pop_16, with_ties = FALSE) %>%
  ungroup()

# save 
data %>%
  write_csv("data/processed/csd_popultion.csv")

# 13.0726 secs