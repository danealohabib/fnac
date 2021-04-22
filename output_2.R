
pacman::p_load(tidyverse, janitor, scales, here)


source(file = here("script/functions.R"))

# set output

output <- here("output")

# import data for distance measures

distance_data <- read_csv("data/processed/distance_processed.csv")

#########################################

# process data for chart 4

cor_within_20 <- distance_data %>% filter(travel_wo_nw < 20)

cor_1 <- round(cor(cor_within_20$geo_wo_nw, cor_within_20$travel_wo_nw), 2)

cor_over_20 <- distance_data %>% filter(travel_wo_nw > 20)

cor_2 <- round(cor(cor_over_20$geo_wo_nw, cor_over_20$travel_wo_nw), 2)

# chart 4

distance_data %>%
  ggplot(aes(geo_wo_nw, travel_na_wo_nw)) +
  geom_point(alpha = 0.4) +
  geom_abline(slope = 1, intercept = 0) +
  theme_minimal() +
  annotate("text",
    x = 138,
    y = 42,
    label = paste0("correlation coefficient within 20 km = ", cor_1, "\ncorrelation coefficient over 20 km = ", cor_2)
  ) +
  scale_y_continuous(breaks = seq(0, 500, 50), limits = c(0, 500)) +
  scale_x_continuous(breaks = seq(0, 250, 25)) +
  labs(
    x = "geographic distance (km)",
    y = "travel distance (km)",
    subtitle = "",
    title = "",
    caption = ""
  )

ggsave(path = output, "chart_4.png")

# chart 5
distance_data %>%
  mutate(over_20_km = ifelse(travel_wo_nw <= 20, "yes", "no")) %>%
  ggplot(aes(geo_wo_nw, travel_wo_nw, color = over_20_km)) +
  geom_point(alpha = 0.4) +
  theme_minimal() +
  geom_abline(slope = 1, intercept = 0) +
  scale_y_continuous(breaks = seq(0, 500, 50), limits = c(0, 500)) +
  scale_x_continuous(breaks = seq(0, 250, 25)) +
  geom_hline(yintercept = 20, linetype = "dashed", color = "red") +
  labs(
    x = "geographic distance (km)",
    y = "travel distance (km)",
    subtitle = "",
    title = "",
    caption = "horizontal line drawn at 20 km\nright censored missing travel distance at 500 km",
    color = "within 20 km"
  )

ggsave(path = output, "chart_5.png")

# chart 6
distance_data %>%
  ggplot(aes(travel_wo_nw)) +
  stat_ecdf(geom = "step", pad = FALSE) +
  theme_minimal() +
  labs(x = "KM", y = "") +
  scale_y_continuous(labels = percent)

ggsave(path = output, "chart_6.png")


# chart 7
distance_data %>%
  filter(travel_wo_nw < 500) %>%
  mutate(cash_type = case_when(
    type == "wl" ~ "WL-ATM",
    type == "branch" ~ "FI Branches and ATMs",
    type == "fi" ~ "FI Branches and ATMs",
    type == "nw" ~ "NWCo Stores, excel ATMs"
  )) %>%
  count(cash_type) %>%
  mutate(percent = n / 637) %>%
  mutate(
    cash_type = as.factor(cash_type),
    cash_type = fct_reorder(cash_type, percent)
  ) %>%
  ggplot(aes(cash_type, percent)) +
  geom_col(width = 0.7) +
  theme_minimal() +
  coord_flip() +
  scale_y_continuous(labels = percent) +
  labs(
    x = "",
    y = "",
    subtitle = "Road distance",
    title = "",
    caption = ""
  )

ggsave(path = output, "chart_7.png")


########################################

# code to generated plot 1 and 2 if needed 

# chart 1 plot reserves
# ggplot(prov_2011) +
#   geom_sf() +
#   geom_sf(data = first_nation_4269_shape) +
#   theme_minimal() +
#   labs(caption = "Band office addresses as registered in Indigenous and Northern Affairs Canada (INAC)")
# 
# ggsave(path = output, "chart_1.png")
# 
# # chart 2 plot cash sources

# ggplot(prov_2011) +
#   geom_sf() +
#   geom_sf(data = atm_18_sf, alpha = .1) +
#   theme_minimal()

# ggsave(path = output, "chart_2.png")
