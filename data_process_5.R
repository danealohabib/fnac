
pacman::p_load(tidyverse, sf, janitor, nngeo, scales)

# load census boundry files
census_subdivision <- st_read("data/unprocessed/csd_shp/lcsd000b16a_e.shp") %>%
  clean_names() %>%
  st_transform(., crs = 4326)

# load population center
pop_shp_16 <- st_read("data/unprocessed/pop_centres_shp/pop_shp_16.shp") %>%
  rowid_to_column(., "pop_center_id") %>%
  st_transform(., crs = 4326)

# import first nation shape files
first_nation_4269_shape <- st_read(
  "data/unprocessed/first_nation_shp",
  "Premiere_Nation_First_Nation"
) %>%
  st_transform(., crs = 4326) %>%
  rowid_to_column(., "row_id") %>%
  clean_names()

# first nations drop geometry
first_nation <- first_nation_4269_shape %>%
  st_drop_geometry()

# import mc data
atm_processed_18 <- read_csv("data/processed/atm_processed_18.csv",
  guess_max = 100000
)
# convert mc to sf
atm_18_sf <- atm_processed_18 %>%
  st_as_sf(., coords = c("lon", "lat"), crs = 4326)

# import population data for CSD

csd_data <- read_csv("data/processed/csd_popultion.csv")

# old data
# pop_data <- read_csv("data/processed/csd_census/pop_band_csd.csv") %>%
# rename(pop_16 = population_2016)

# import distance data
distance_data <- read_csv("data/processed/distance_processed.csv")

####################################################

# find nearest pop center for each band office
# get distance
pop_center <- st_nn(first_nation_4269_shape, pop_shp_16,
  returnDist = T, k = 1, progress = TRUE
)

####################################################

pop_distance <- tibble(
  pop_center_id = unlist(pop_center[[1]]),
  pop_center_distance = unlist(pop_center[[2]])
)

pop_distance <- pop_distance %>%
  mutate(pop_center_distance = pop_center_distance / 1000) %>%
  rowid_to_column(., "row_id") %>%
  inner_join(first_nation) %>%
  inner_join(pop_shp_16 %>% st_drop_geometry())

# see distribution of distance to pop center
hist(pop_distance$pop_center_distance,
  xlab = "Distance to Pop. Center (km)",
  main = "Distance to Pop. Center from Band Office"
)

hist(log(pop_distance$pop_center_distance),
  xlab = "Distance to Pop. Center (km)",
  main = "Distance to Pop. Center from Band Office"
)

#######################################################

# define reserve csd
reserve_csds <- c("IRI", "S-É", "IGD", "TC", "TK", "NL")

# see which CSD each band office belongs to

join_census <- st_join(first_nation_4269_shape, census_subdivision, join = st_intersects) %>%
  mutate(office_reserve = ifelse(csdtype %in% reserve_csds, "reserve csd", "other csd")) %>%
  st_drop_geometry() %>%
  as_tibble() %>%
  select(row_id, band_name, csdname, office_reserve, prname)

# join data
band_summary_stats <- join_census %>%
  left_join(pop_distance %>% select(row_id, pop_center_distance)) %>%
  left_join(csd_pop) %>%
  left_join(distance_data)

# select final variables and save data
band_summary_stats %>% 
  select(row_id, band_name, csdname, office_reserve, prname, pop_center_distance, pop_16) %>% 
  write_csv("data/processed/band_summary_stats.csv")



#########################################


# map ATM to census boundary
#join_census_sf <- st_join(atm_18_sf, census_subdivision, join = st_intersects)

# count ATM within reserves
#reserve_csd_atms <- join_census_sf %>%
#mutate(office_reserve = ifelse(csdtype %in% reserve_csds, "reserve csd", "other csd")) %>%
#filter(office_reserve == "reserve csd") %>%
#st_drop_geometry()

# band_summary_stats <- join_census %>%
#   left_join(pop_distance %>% select(row_id, pop_center_distance)) %>%
#   left_join(pop_data) %>%
#   left_join(distance_data)