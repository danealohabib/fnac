
ptm <- proc.time()

# load packages
pacman::p_load(tidyverse, janitor, ggmap)

# read API 
api_key <- read_lines("api/api_key.txt")

# activate API 
register_google(key = api_key) 

# read raw ATM data

atm_unprocessed_18 <- read_csv(
  "data/unprocessed/mastercard/BankOfCanada_HistoricATM_Data_2018.txt",
  guess_max = 100000 ) %>%
  # clean names using the janitor package
  clean_names()

# read owners

fi_owners <- read_lines("data/unprocessed/fi_atm_owners/fi_atm_owners.txt")

# MC data has some missing lon lat data
# geocode some missing lon lat data using the addresses provided

missing_atm_geocode_18 <- atm_unprocessed_18 %>% 
  # filter for all ATMs with missing coordinates
  filter(is.na(latitude)) %>%
  mutate(Canada = "CANADA") %>%
  # prepare address to geocode
  mutate(address_paste = paste0(address_ln1, sep = " ", 
                                city_town, sep = " ", 
                                state_prov, sep = " ", 
                                city_town, sep = " ", 
                                Canada)) %>%
  mutate_geocode(address_paste, output = "more")

atm_processed_18 <- atm_unprocessed_18 %>%
  # join missing geocode data to complete ATM data
  left_join(missing_atm_geocode_18) %>% 
  mutate(
    missing_imputed = if_else(is.na(latitude), 1, 0),
    lon = ifelse(is.na(lon), longitude, lon),
    lat = ifelse(is.na(lat), latitude, lat),
    # flag FI ATM owners
    fi_atm = ifelse(owner_name %in% fi_owners, 1, 0),
    fi_atm = ifelse(fi_atm == 0 & loc_type_desc == "Financial Institution", 1, fi_atm),
    #fi_atm = ifelse(str_detect(location_name, "CREDIT UNION") & fi_atm == 0, 1, fi_atm),
    coordinates_lat_long = paste0(lat, sep = ",", lon)) %>% drop_na(lat)

write_csv(atm_processed_18, "data/processed/atm_processed_18.csv")

# user  system elapsed 
# 40.27    0.83  659.77 