
# get lowest distance

lowest_travel <- function(data) {
  data %>% 
    group_by(type) %>% 
    arrange(distance) %>% 
    head(1)
}


## A function to mutate the comma-separated coordinate pairs into proper format for API
coord_fx <- function(x) {
  x %>% str_replace(., ",", "+") %>%
    return()
}

reserve_csds <- c("IRI", "S-É", "IGD", "TC", "TK", "NL")


