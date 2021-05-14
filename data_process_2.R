
# load packages
pacman::p_load(tidyverse, janitor, ggmap, rvest)

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
    coordinates_lat_long = paste0(lat, sep = ",", lon))

# Arctic ATMs that we couldn't impute

arctic_atm <- atm_processed_18 %>% 
  filter(state_prov %in% c("NU", "YT", "NT")) %>% 
  filter(str_detect(owner_name, "CO OP") | str_detect(location_name, "CO OP")) %>% 
  filter(city_town != "POND INLET") %>% 
  filter(is.na(lon) | missing_imputed == 1)

# pull location name
arctic_atm_locations <- arctic_atm %>% 
  pull(location_name) %>% 
  str_to_title() %>% 
  word(1)

# web scrape arctic store locations

# co op store website
co_webpage <- read_html("https://arctic-coop.com/index.php/member-co-ops/")


# pull html node - address
co_webpage_address_list <- co_webpage %>%
  html_nodes(".uael-heading-wrapper , .uael-size--default") %>% 
  html_text() %>%
  str_replace_all("[\r\t]", "") %>%
  str_replace_all("[\r\n]", "") 

co_addresses <- co_webpage_address_list %>%
  as_tibble() %>%
  filter(row_number() %% 2 != 0) %>%
  rename(full_address = "value") %>%
  rowid_to_column(., "coop_id") %>% 
  mutate(full_address = ifelse(coop_id > 9, str_sub(full_address, 4, -1), str_sub(full_address, 3, -1))) %>% 
  mutate(full_address = trimws(full_address)) %>% 
  mutate_geocode(full_address)

# pull only the locations we need 
arctic_atm_geocode <- co_addresses %>% 
  filter(str_detect(full_address, paste(atm_locations, collapse = '|'))) %>% 
  mutate(store_location = word(full_address, 1))

# split location

location_list <- split(arctic_atm_geocode, arctic_atm_geocode$store_location)

# fill in lon/lat from missing atms


atm_processed_18 <- atm_processed_18 %>%
  mutate(
    lon = ifelse(location_name == "LUTSEL K'S CO-OP", location_list[["Lutsel"]][["lon"]], lon),
    lat = ifelse(location_name == "LUTSEL K'S CO-OP", location_list[["Lutsel"]][["lat"]], lat),
    lon = ifelse(location_name == "PALEAJOOK CO OP", location_list[["Paleajook"]][["lon"]], lon),
    lat = ifelse(location_name == "PALEAJOOK CO OP", location_list[["Paleajook"]][["lat"]], lat),
    lon = ifelse(location_name == "MITIQ CO OP ASSOCIATION LTD", location_list[["Mitiq"]][["lon"]], lon),
    lat = ifelse(location_name == "MITIQ CO OP ASSOCIATION LTD", location_list[["Mitiq"]][["lat"]], lat),
    lon = ifelse(location_name == "PITSIULAK CO OP", location_list[["Pitsiulak"]][["lon"]], lon),
    lat = ifelse(location_name == "PITSIULAK CO OP", location_list[["Pitsiulak"]][["lat"]], lat),
    lon = ifelse(location_name == "SANAVIK COOP", location_list[["Sanavik"]][["lon"]], lon),
    lat = ifelse(location_name == "SANAVIK COOP", location_list[["Sanavik"]][["lat"]], lat),
    coordinates_lat_long = paste0(lat, sep = ",", lon)
    )

write_csv(atm_processed_18, "data/processed/atm_processed_18.csv")

