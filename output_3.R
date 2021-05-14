library(tidyverse)
library(readxl)
library(gt)
library(janitor)

band_summary_stats <- read_csv("data/processed/band_summary_stats.csv")

distance <- read_csv("data/processed/distance_processed.csv")

distance_data <- read_csv("data/processed/old/distance_data_impute.csv")

ferry_routes <- read_csv("data/processed/old/ferry_routes.csv")

coordinates <- read_csv("data/processed/data_coordinates.csv") %>%
  select(row_id, band_name, band_coords)

# read remote index data : https://www150.statcan.gc.ca/n1/pub/17-26-0001/2020001/172600012020001-eng.zip
remoteness_index <- read_csv("data/unprocessed/remote_index/2016IR_DATABASE.csv", guess_max = 10000) %>%
  clean_names() %>%
  mutate(index_of_remoteness = as.numeric(index_of_remoteness)) %>%
  select(csdname = cs_dname, csd_type = cs_dtype, index_remote = index_of_remoteness)

# appendix remote - Walter email in late December 2020
# we wanted all bands that have to travel over 100 km (with travel route)

remote_1 <- distance_data %>%
  filter(travel_w_nw >= 100 & travel_w_nw < 500) %>%
  inner_join(band_summary_stats) %>%
  # filter(travel_500_wo_nw != 500) %>%
  # mutate(pop_16 = ifelse(row_id == 534, 88, pop_16)) %>%
  arrange(prname, band_name) %>%
  select(row_id, band_name, prname, csdname,
    pop_16, office_reserve, pop_center_distance, geo_wo_nw,
    travel_distance = travel_wo_nw
  )

remote_1 %>% 
  gt() %>% 
  gtsave("output/fsrr/tbl_2.html", inline_css = TRUE)

# we wanted all bands without a travel route (all that we right censored)

remote_2 <- distance_data %>%
  filter(travel_wo_nw == 500) %>%
  inner_join(band_summary_stats) %>%
  arrange(prname, band_name) %>%
  select(
    row_id, band_name, prname, csdname,
    pop_16, office_reserve, pop_center_distance, geo_w_nw, geo_wo_nw,
    travel_wo_nw, travel_w_nw
  )

remote_2 %>% 
  gt() %>% 
  gtsave("output/fsrr/tbl_3.html", inline_css = TRUE)

ffsr_remote <- bind_rows(remote_1, remote_2)

# create band offices with travel route to cash that requires a ferry/boat trip

pop_ferry_routes <- ferry_routes %>%
  filter(ferry_route == 1) %>%
  inner_join(band_summary_stats) %>%
  inner_join(distance_data) %>%
  select(band_name, csdname, pop_16, office_reserve, geo_wo_nw, travel_wo_nw)

pop_ferry_routes %>% 
  gt() %>% 
  gtsave("output/fsrr/tbl_4.html", inline_css = TRUE)

# join coordinates to remote data

remote_locations <- coordinates %>%
  inner_join(ffsr_remote) %>%
  select(row_id, band_name, band_coords, csdname)

remote_locations_ferry <- coordinates %>%
  inner_join(pop_ferry_routes) %>%
  select(row_id, band_name, band_coords, csdname)

# create data of all remote locations with summary states
fsrr_remote_final <- bind_rows(remote_locations, remote_locations_ferry %>% filter(row_id != 352)) %>% 
  inner_join(band_summary_stats) %>% 
  inner_join(distance_data) 

# process remote location data
remote_processed <- fsrr_remote_final %>%
  select(band_name, csdname, band_coords) %>%
  right_join(remoteness_index) %>%
  mutate(remote_location = ifelse(is.na(band_coords), "no", "yes"))

# pull remoteness index for the band offices we defined as remote
remote_sample <- remote_processed %>% 
  filter(remote_location == "yes") %>% 
  select(-band_coords, -remote_location)

remote_1 %>% 
  inner_join(remoteness_index) %>% 
  group_by(row_id) %>% 
  mutate(index_remote_2 = max(index_remote)) %>% 
  ungroup() %>% 
  distinct(row_id, index_remote_2) %>% 
  summarise(mean(index_remote_2, na.rm = TRUE))

remote_2 %>% 
  mutate(csdname = ifelse(row_id == 534, "Sambaa K’e", csdname)) %>% 
  inner_join(remoteness_index) %>% 
  summarise(mean(index_remote, na.rm = TRUE))
  
remote_locations_ferry %>% 
  inner_join(remoteness_index) %>% 
  filter(band_name != "Ehattesaht") %>% 
  summarise(mean(index_remote, na.rm = TRUE))

# compute mean remote index for subsample
mean_remote_index <- round(mean(remote_sample$index_remote), 2)

percentile_rank <- remoteness_index %>% 
  mutate(percentile_rank = ntile(index_remote, 100)) %>% 
  filter(index_remote >= mean_remote_index) %>% 
  arrange(index_remote) %>% 
  head(1) %>% 
  pull(percentile_rank)

# create figure 5
chart_5 <- remoteness_index %>% 
  ggplot(aes(index_remote)) +
  geom_histogram(bins = 13, color = "grey30", fill = "white") +
  geom_vline(xintercept = mean_remote_index, color = "red", linetype = "dashed") +
  labs(x = "remoteness index")

ggsave("output/fsrr/chart_5.png")

# broadband


broadband_data <- read_csv("data/processed/broadband_data.csv")

broadband_data <- broadband_data %>%
  # we ended up removing Lutsel 
  inner_join(fsrr_remote_final)

broadband_data$speed <- fct_relevel(broadband_data$speed, "<5/1 Mbps", "5/1 Mbps", "25/5 Mbps")

low_speed <- broadband_data %>% 
  drop_na(speed) %>% 
  filter(str_detect(speed, "5/")) %>% 
  nrow() 

sum(is.na(broadband_data$speed))

chart_2 <- broadband_data %>% 
  count(speed) %>% 
  mutate(speed = fct_explicit_na(speed, na_level = "Satellite direct-to-home")) %>% 
  ggplot(aes(speed, n)) + 
  geom_col() + 
  labs(caption = "",
       title = "First Nations Remote Sample: Internet Access ",
       y = "number of remote locations") +
  theme_light() +
  scale_x_discrete(labels = c("<5/1 Mbps", "5/1 Mbps", "25/5 Mbps", "50/10 Mbps", "Satellite\ndirect-to-home"))

ggsave("output/fsrr/chart_2.png")

# community wellbeing index

cwb <- read_excel("data/unprocessed/cwb/CWB_2016_DATA_1557324628212_eng.xlsx") %>% 
  clean_names() %>% 
  mutate(community = ifelse(str_detect(community, "First"), "first nations", community),
         community = ifelse(str_detect(community, "Inuit"), "inuit", community),
         community = ifelse(str_detect(community, "Non"), "non-indigenous", community))

cwb %>% 
  mutate(grp = (income_2016*0.693147)+7.600902) %>% 
  mutate(grp_2 = (income_2016*log(4000) - log(2000))+log(2000)) 

cwb %>% 
  select(community, cwb_2016, csdname) %>% 
  inner_join(remoteness_index) %>% 
  arrange(csdname) %>% 
  filter(community != "inuit") %>% 
  #inner_join(band_summary_stats) %>% 
  #inner_join(distance_data) %>% 
  ggplot(aes(index_remote, cwb_2016, color = community)) + 
  geom_point(alpha = .2) + 
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "remoteness index", y = "community well-being")

hist(cwb$cwb_2016, xlab = "community well-being index", main = "histogram cwb")

mean_cwb <- cwb %>% 
  select(community, cwb_2016, csdname) %>% 
  #inner_join(remoteness_index) %>% 
  inner_join(fsrr_remote_final) %>% 
  summarise(mean_cwb = mean(cwb_2016, na.rm = TRUE)) %>% 
  pull(mean_cwb)

cwb %>% 
  inner_join(fsrr_remote_final) %>%
  filter(is.na(cwb_2016)) %>% 
  nrow()

# 12/49 are missing
# mean cwb is 63.67 

cwb %>% 
  select(community, cwb_2016, csdname) %>% 
  inner_join(remoteness_index) %>% 
  arrange(csdname) %>% 
  filter(community != "inuit") %>% 
  ggplot(aes(cwb_2016, fill = community)) + geom_density(alpha = .2) +
  geom_vline(xintercept = mean_cwb, color = "red", linetype = "dashed") +
  labs(x = "Community Well-Being Index",
       fill = "")

cwb %>% 
  select(community, cwb_2016, csdname) %>% 
  #inner_join(remoteness_index) %>% 
  #arrange(csdname) %>% 
  filter(community != "inuit") %>% 
  ggplot(aes(cwb_2016)) + geom_histogram(bins = 13, color = "grey30", fill = "white") +
  geom_vline(xintercept = mean_cwb, color = "red", linetype = "dashed") +
  labs(x = "Community Well-Being Index")

# compute mean remote index for subsample

percentile_rank_cwb <- cwb %>% 
  mutate(percentile_cwb = ntile(cwb_2016, 100)) %>% 
  filter(cwb_2016 >= mean_cwb) %>% 
  arrange(cwb_2016) %>% 
  head(1) %>% 
  pull(percentile_cwb)

###

library(sf)
# prov shape

remote_sf <- fsrr_remote_final %>% 
  separate(band_coords, c('lat', 'lon'), sep=",") %>% 
  st_as_sf(., coords = c("lat", "lon"), crs = 4326)

prov_2011 <- st_read("data/unprocessed/shape_files/province_shape/gpr_000b11a_e.shp") %>% 
  st_transform(., crs = "+proj=lcc +lat_1=49 +lat_2=77 +lon_0=-91.52 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs")

###################################################################

# plot cash sources - chart 1
ggplot(prov_2011) + 
  geom_sf() + 
  geom_sf(data = remote_sf) +
  theme_minimal()

# plot 1 output
ggsave("output/fsrr/chart_1.png")


# remote

fsrr_remote_final %>% 
  filter(travel_wo_nw == 500) %>% 
  inner_join(remoteness_index)

# output

fsrr_remote_final %>%
  write_csv("data/processed/remote_locations.csv")
