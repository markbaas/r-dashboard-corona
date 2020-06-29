# Get historic/cached data.

air.history <- read_rds("results/air.Rds")

components <- list(
  PM2.5 = "012502d5-6a46-479b-b1a3-1f005e9de998",
  PM10 = "567663c8-27a4-4bc2-aa8d-d6b56baaed5b",
  O3 = "460f0fa9-40a2-4c9c-9533-20d0135be687",
  NO2 = "6274c56d-4554-4f08-9d49-30aafd868349",
  NO = "907513b2-c0e2-44c4-af27-789a91efc6dd"
)

dates <- expand.grid(Month = seq(1,12), Year = seq(2014, 2019), Variable = components) %>%
  mutate(
    start = format(as.Date(ISOdate(Year, Month, 1)), "%Y-%m%-%dT00:00:00"),
    end = format(as.Date(ISOdate(Year, Month, 1) %m+% months(1)) - 1, "%Y-%m%-%dT23:59:59"),
  )

air.luchtmeetnet.historic <- data.frame()
for (row in 1:nrow(dates)) {
  start = dates[row, "start"]
  end = dates[row, "end"]
  name = names(dates[row, "Variable"])
  component = dates[row, "Variable"]
  
  url <- "https://api2020.luchtmeetnet.nl/sos/measurements/csv?sos_component_id={component}&sos_report_id=34d04bda-f739-4e9b-94e9-3e2ffae5e0db&start_date={start}&end_date={end}" %>% glue()
  
  print(url)
  
  data <-
    GET(url) %>% content(as = "raw") %>% read_delim(delim = ";", na = c("-")) %>% 
    gather(Station, Value, -X1) %>% 
    mutate(Variable = !!name) 
  
  air.luchtmeetnet.historic <- data %>% union_all(air.luchtmeetnet.historic)
}

air2 <- air.luchtmeetnet.historic %>% filter(X1 != "Alle meetpunten" & X1 != "microgram/m3") %>% distinct() %>% drop_na()
write_rds(air.luchtmeetnet.historic, "../results/air.RDS", compress = "gz")

read_rds("data/nl/air.RDS") %>% drop_na() %>% mutate(
  Date = date(ymd_hm(X1))
) %>%
  group_by(Date, Station, Variable) %>% summarise(Value = mean(Value)) %>%
  ungroup() %>% write_rds("results/luchtmeetnet.Rds")
