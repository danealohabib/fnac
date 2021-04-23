# load packages
pacman::p_load(tidyverse, janitor, ggmap, rvest)

# read API key
api_key <- read_lines("api/api_key.txt")

# activate API
register_google(key = api_key)

# nw store website
northern_webpage <- read_html("https://www.northmart.ca/our-stores/locator")

# pull html node - address
nw_address_list <- northern_webpage %>%
  html_nodes("strong") %>%
  html_text() %>%
  str_replace_all("[\r\n]", ", ") %>%
  str_replace_all("[\r\t]", "")
# str_split_fixed(", ", n = 4)

# pull html node - store name (Northern store, Northmart ect)
nw_store_list <- northern_webpage %>%
  html_nodes("span") %>%
  html_text() %>%
  as_tibble() %>%
  rowid_to_column(., "store_id") %>%
  rename(store = "value")

nw_address <- nw_address_list %>%
  as_tibble() %>%
  rename(full_address = "value") %>%
  rowid_to_column(., "store_id")

# some addesses are not formatted correctly
# subset this data and join later
edit_address <- nw_address %>%
  filter(
    store_id %in% c("8", "21", "22", "23", "29", "32", "52", "91", "110")
  ) %>%
  inner_join(., nw_store_list)

# create data first without weirdly edited addresses
nw_data <- nw_address %>%
  filter(!store_id %in% c("8", "21", "22", "23", "29", "32", "52", "91", "110")) %>%
  separate(
    full_address,
    c("address", "city", "province", "postal_code"),
    sep = ", ", remove = FALSE
  ) %>%
  mutate(fsa = str_sub(postal_code, 1, -5)) %>%
  inner_join(., nw_store_list) %>%
  mutate(address_geocode = ifelse(
    str_detect(address, "Box|General Delivery"),
    paste0(store,
      sep = " ",
      city, sep = " ",
      province, sep = " ",
      fsa
    ),
    paste0(store,
      sep = " ",
      address, sep = " ",
      city, sep = " ",
      province, sep = " ",
      fsa
    )
  )) %>%
  bind_rows(edit_address) %>%
  # manually edited some addresses
  mutate(address_geocode = case_when(
    store_id == 8 ~ "Northern Store Garden Hill, Manitoba, R0B",
    store_id == 21 ~ "Northern Store Rossville, Manitoba, R0B",
    store_id == 22 ~ "Quickstop  Rossville Manitoba",
    store_id == 23 ~ "Northern Store ,Pelican Rapids, Manitoba",
    store_id == 29 ~ "Northern Store, 125 2 St W, The Pas, Manitoba R9A",
    store_id == 32 ~ "Northern Store, 90 Hamilton River Rd, Happy Valley-Goose Bay, NL",
    store_id == 52 ~ "northern store Holman Island, Ulukhaktok",
    store_id == 91 ~ "northern store Fort Severn, Severn, Ontario, P0V",
    store_id == 110 ~ "northern store Chisasibi, QC",
    TRUE ~ address_geocode
  )) %>%
  add_row(store_id = 122, address_geocode = "Northern Store Stevenson Island Manitoba") %>%
  add_row(store_id = 123, address_geocode = "Northern Store, Norway House, Manitoba")

# geo code northwest store addresses
nw_geocode <- nw_data %>%
  mutate_geocode(address_geocode)

# fill in Lansdowne House 

#nw_geocode_final <- nw_geocode %>% 
 # mutate(lon = ifelse(is.na(lon), -87.89479857107976, lon),
  #       lat = ifelse(is.na(lat), 52.218108341182585, lat))

# save nw store geo code data
write_csv(nw_geocode, "data/processed/nw_geocode.csv")

