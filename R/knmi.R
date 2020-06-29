library(tidyverse)
library(httr)

knmi_get_data <- function(start, end, vars, stns) {
  r <- POST(
    "http://projects.knmi.nl/klimatologie/daggegevens/getdata_dag.cgi",
    body = list(
      start = start,
      end = end,
      vars = vars,
      stns = stns
    )
  )
  
  measurements <- content(r, as = "raw") %>%
    read_delim(
      ",",
      comment = "#",
      col_names = c("Station", "Date", "Temperature"),
      col_types = "ici",
      trim_ws = TRUE
    )
  
  stations <- content(r, as = "raw") %>% 
    read_lines() %>% data.frame(X1 = .) %>% filter(str_detect(X1, "# \\d+:")) %>%
    separate(X1, into = c("Station", "Lat", "Lon", "Alt", "Name"), sep = "\\s{2,}") %>%
    mutate(
      Station = Station %>% str_match("# (\\d+)\\:") %>% .[,2] %>% as.numeric(),
      Lon = as.numeric(Lon),
      Lat = as.numeric(Lat)
    )
  
  temp <- measurements %>% left_join(stations)
  
  return(temp)
}