
pacman::p_load(tidyverse, sf, janitor, nngeo, here, gmapsdistance, ggmap, scales, googleway)

# Source functions
source(file = here("script/functions.R"))

# import first nation shape files
first_nation_4269_shape <- st_read(
  "data/unprocessed/first_nation_shp",
  "Premiere_Nation_First_Nation"
) %>%
  st_transform(., crs = 4326) %>%
  rowid_to_column(., "row_id") %>%
  clean_names()

# create band coordinates
# used to for google API
band_coordinates <- first_nation_4269_shape %>%
  st_coordinates() %>%
  as_tibble() %>%
  rowid_to_column(., "row_id") %>%
  mutate(band_coords = paste0(Y, sep = ",", X))

# import mc data
atm_processed_18 <- read_csv("data/processed/atm_processed_18.csv",
  guess_max = 100000
)
# convert mc to sf
atm_18_sf <- atm_processed_18 %>%
  st_as_sf(., coords = c("lon", "lat"), crs = 4326)

# filter FI atm
fi_atm_18_sf <- atm_18_sf %>%
  filter(fi_atm == 1) %>%
  rowid_to_column(., "id")

# filter wl atm
wl_atm_18_sf <- atm_18_sf %>%
  filter(fi_atm == 0) %>%
  rowid_to_column(., "id")

# import branch 18
branch_18 <- read_csv("data/unprocessed/fif/branches_exact_fsa.csv",
  guess_max = 50000
) %>%
  clean_names() %>%
  mutate(coordinates_branch = paste0(lat, sep = ",", lng)) %>%
  filter(
    year == 2018,
    duplicate_flag != 1
  ) %>%
  drop_na(lng) %>%
  rowid_to_column(., "branch_id")

# import branch 18 sf
branch_18_sf <- branch_18 %>%
  clean_names() %>%
  st_as_sf(., coords = c("lng", "lat"), crs = 4326)

# import nw and convert to sf
nw_locations <- read_csv("data/processed/nw_geocode.csv") %>%
  drop_na(lon) %>%
  mutate(nw_coordinates = paste0(lat, sep = ",", lon)) %>%
  st_as_sf(., coords = c("lon", "lat"), crs = 4326)

#########################################################################

# nearest wl atm
nearest_wl_atm_18 <- st_nn(first_nation_4269_shape, wl_atm_18_sf,
  returnDist = T, k = 1, progress = TRUE
)

# nearest fi atm
nearest_fi_atm_18 <- st_nn(first_nation_4269_shape, fi_atm_18_sf,
  returnDist = T, k = 1, progress = TRUE
)

# nearest branch
nearest_branch_18 <- st_nn(first_nation_4269_shape, branch_18_sf,
  returnDist = T, k = 1, progress = TRUE
)

# nearest nw
nearest_nw_18 <- st_nn(first_nation_4269_shape, nw_locations,
  returnDist = T, k = 1, progress = TRUE
)

############################################################################

# extract cash source ID and geo distance
geo_distance <- tibble(
  geo_wl_atm = unlist(nearest_wl_atm_18[[2]]),
  geo_fi_atm = unlist(nearest_fi_atm_18[[2]]),
  geo_branch = unlist(nearest_branch_18[[2]]),
  geo_nw = unlist(nearest_nw_18[[2]])
) %>%
  rowid_to_column(., "row_id") %>%
  mutate(
    geo_wl_atm = geo_wl_atm / 1000,
    geo_fi_atm = geo_fi_atm / 1000,
    geo_branch = geo_branch / 1000,
    geo_nw = geo_nw / 1000
  )

##################################################

# join with band id with cash id and pull the coordinates for the cash source
# this data sets gives us the coordinates of the band office (our origin)
# and the coordinates of the nearest cash source by each type

data_coordinates <- tibble(
  id = unlist(nearest_wl_atm_18[[1]]),
) %>%
  rowid_to_column(., "row_id") %>%
  inner_join(wl_atm_18_sf %>%
    st_drop_geometry()) %>%
  select(row_id, wl = coordinates_lat_long) %>%
  mutate(id = unlist(nearest_fi_atm_18[[1]])) %>%
  inner_join(fi_atm_18_sf %>%
    st_drop_geometry()) %>%
  select(row_id,
    wl,
    fi = coordinates_lat_long
  ) %>%
  mutate(branch_id = unlist(nearest_branch_18[[1]])) %>%
  inner_join(branch_18_sf %>%
    st_drop_geometry()) %>%
  select(row_id, wl, fi, branch = coordinates_branch) %>%
  mutate(store_id = unlist(nearest_nw_18[[1]])) %>%
  inner_join(nw_locations %>%
    st_drop_geometry()) %>%
  select(row_id, wl, fi, branch, nw = nw_coordinates) %>%
  inner_join(first_nation_4269_shape %>%
    st_drop_geometry() %>% select(row_id, band_name)) %>%
  inner_join(band_coordinates) %>%
  select(row_id, band_name, band_coords, wl, fi, branch, nw)

#########################################################

# feed these coordinates into google api to get travel distance

key <- read_lines("api/api_key.txt")

# 1 = bicycling, 2 = walking, 3 = public transit, 4 = driving
mode <- 4

# a table to convert user input mode to string format for api
api_modes <- c("bicycling", "walking", "transit", "driving")

# prompt API for travel
#  travel distance for nearest WL atm

api_return_wl <- gmapsdistance(
  origin = data_coordinates %>% pull(3) %>% coord_fx(),
  destination = data_coordinates %>% pull(4) %>% coord_fx(),
  mode = api_modes[mode], ## selected at top by user
  combinations = "pairwise", ## do not change
  key = key
) ## provided at top of script

api_return_fi <- gmapsdistance(
  origin = data_coordinates %>% pull(3) %>% coord_fx(),
  destination = data_coordinates %>% pull(5) %>% coord_fx(),
  mode = api_modes[mode],
  combinations = "pairwise",
  key = key
)

api_return_br <- gmapsdistance(
  origin = data_coordinates %>% pull(3) %>% coord_fx(),
  destination = data_coordinates %>% pull(6) %>% coord_fx(),
  mode = api_modes[mode],
  combinations = "pairwise",
  key = key
)

api_return_nw <- gmapsdistance(
  origin = data_coordinates %>% pull(3) %>% coord_fx(),
  destination = data_coordinates %>% pull(7) %>% coord_fx(),
  mode = api_modes[mode],
  combinations = "pairwise",
  key = key
)

##############################################################

distance <- geo_distance %>%
  mutate(
    travel_fi_atm = api_return_fi$Distance$Distance / 1000,
    travel_wl_atm = api_return_wl$Distance$Distance / 1000,
    travel_branch = api_return_br$Distance$Distance / 1000,
    travel_nw = api_return_nw$Distance$Distance / 1000
  ) %>%
  mutate(
    travel_wl_atm_impute = ifelse(is.na(travel_wl_atm) & geo_wl_atm <= 20, geo_wl_atm, travel_wl_atm),
    travel_fi_atm_impute = ifelse(is.na(travel_fi_atm) & geo_fi_atm <= 20, geo_fi_atm, travel_fi_atm),
    travel_branch_impute = ifelse(is.na(travel_branch) & geo_branch <= 20, geo_branch, travel_branch),
    travel_nw_impute = ifelse(is.na(travel_nw) & geo_nw <= 20, geo_nw, travel_nw)
  ) %>%
  mutate(
    travel_wl_atm_500 = ifelse(is.na(travel_wl_atm_impute), 500, travel_wl_atm_impute),
    travel_fi_atm_500 = ifelse(is.na(travel_fi_atm_impute), 500, travel_fi_atm_impute),
    travel_branch_500 = ifelse(is.na(travel_branch_impute), 500, travel_branch_impute),
    travel_nw_500 = ifelse(is.na(travel_nw_impute), 500, travel_nw_impute)
  )

###############################################################

# process distance data

# need to compute nearest distance with and without nw
distance_processed <- distance %>%
  nest(data = c(geo_wl_atm:geo_nw)) %>%
  # geo distance - w nw
  mutate(geo_w_nw = map(data, min)) %>%
  unnest(data) %>%
  nest(data = c(geo_wl_atm:geo_branch)) %>%
  # geo distance - wo nw
  mutate(geo_wo_nw = map(data, min)) %>%
  unnest(data) %>%
  nest(data = c(travel_wl_atm_500:travel_nw_500)) %>%
  # travel distance w nw
  mutate(travel_w_nw = map(data, min)) %>%
  unnest(data) %>%
  nest(data = c(travel_wl_atm_500:travel_branch_500)) %>%
  # travel distance wo nw
  mutate(travel_wo_nw = map(data, min)) %>%
  unnest(data) %>%
  nest(data = c(travel_fi_atm:travel_branch)) %>%
  # travel distance without any impute/topcode
  mutate(travel_na_wo_nw = map(data, min)) %>%
  unnest(data) %>%
  unnest(c(geo_w_nw, geo_wo_nw, travel_w_nw, travel_wo_nw, travel_na_wo_nw))

###################################################################

# create ferry routes

join <- data_coordinates %>% 
  select(-band_name) %>% 
  pivot_longer(cols = wl:nw, names_to = 'type') %>% 
  rename(destination = value,
         origin_coords = band_coords)

flag_ferry_routes <- distance_processed %>% 
  select(row_id, contains("500")) %>% 
  pivot_longer(!row_id) %>% 
  mutate(name = str_replace(name, 'travel_', '')) %>% 
  mutate(name = str_replace(name, '_500', '')) %>% 
  mutate(name = str_replace(name, '_atm', '')) %>%
  rename(distance = value) %>% 
  group_by(row_id) %>%
  # column name which has the minimum distance
  # used to Id the destination and later to create figure 7
  mutate(type = if(all(is.na(distance))) NA else name[which.min(distance)]) %>%
  ungroup() %>% 
  distinct(row_id, type) %>% 
  inner_join(join) %>% 
  separate(origin_coords, c('origin_lat', 'origin_lon'), sep = ',', convert = TRUE) %>% 
  separate(destination , c('destination_lat', 'destination_lon'), sep = ',', convert = TRUE) %>% 
  rowwise() %>%
  mutate(ferry_route = {
    tryCatch({
      tmp <- google_directions(origin = select(cur_data(), origin_lat,origin_lon), 
                               destination = select(cur_data(), destination_lat, destination_lon), 
                               key = api_key)
      +(any(tmp$routes$legs[[1]]$steps[[1]]$maneuver == 'ferry', na.rm = TRUE))
    }, error = function(e) NA)
    
  }) %>% 
  select(row_id, type, ferry_route)

# save ferry route data 

flag_ferry_routes %>% 
  write_csv("data/processed/ferry_routes.csv")

#######################################

# save final distance data

# select final variables
distance_processed <- distance_processed %>%
  inner_join(flag_ferry_routes) %>% 
  select(
    row_id, geo_w_nw, geo_wo_nw,
    travel_wl_atm_500, travel_fi_atm_500, travel_branch_500,
    travel_wo_nw, travel_w_nw,
    geo_fi_atm, geo_wl_atm, geo_branch,
    travel_na_wo_nw, type
  )

# save processed distance data

distance_processed %>% 
  write_csv("data/processed/distance_processed.csv")
