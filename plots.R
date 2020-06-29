
data.labels = data.frame(
  "Variable" = c(
    "AvgMortality",
    "ExpectedMortality",
    "MortalityRate",
    "Flu2018",
    "Rivm",
    "DeathsAboveAvg",
    "DeathsUnexpected",
    "Deaths",
    "YearHighestMort"
  ),
  "Label" = c(
    "Average Mortality",
    "Expected Mortality **",
    "Coronavirus (2020)",
    "Flu Epidemic (2018)",
    "Reported by RIVM",
    "Above average",
    "Unexpected **",
    "Deaths (any cause)",
    "Year highest mortality"
  )
)

data.mort_over_time_all <- read_rds("results/plots/mortovertime.Rds") %>%
  left_join(data.labels)

data.mort_over_time <- data.mort_over_time_all %>%
  filter(Variable %in% c("MortalityRate", "ExpectedMortality", "AvgMortality", "Flu2018"))

data.emort_over_time <- data.mort_over_time_all %>% 
  filter(Variable %in% c("Rivm", "DeathsAboveAvg", "DeathsUnexpected"))

data.mort_spatial <- read_rds("results/plots/spatial_absolute.Rds")

data.summary <- read_rds("results/plots/summary.Rds")

regions = data.mort_spatial %>% select(Name = Gemeentenaam, Regio = RegioS) %>% 
  st_drop_geometry() %>% distinct() %>% add_row(Name = "Nederland", Regio = "NL")

renderPlotMortOverTime <- function(input) {
  output <- renderPlotly({ 
    x <- data.mort_over_time %>% filter(Regio == input$region)

    if (x %>% count() == 0) return()
    
    tooltip <- ("<b>{Date}</b>
Mortality rate: {floor(Value)}
Deaths: {floor(Absolute)}"
    )
    
    ggplotly(tooltip = "text", ggplot(
      x,
      aes(
        group = Label,
        color = Label,
        text = tooltip %>% glue()
      )
    ) +
      geom_point(aes(x = Date, y = Value)) +
      geom_line(aes(x = Date, y = Interpolated, text = NULL)) +
      labs(x = "Date" %>% glue(), y = "Deaths by 100.000 inhabitants") +
      theme_minimal() +
      theme(legend.title = element_blank())
    ) 
  })
  
  return(output)
}

renderPlotExcessiveMortOverTime <- function(input) {
  output <- renderPlotly({
    x <- data.emort_over_time %>% filter(Regio == input$region)
    
    if (x %>% count() == 0) return()
    
    tooltip <- ("<b>{Date}</b>
Deaths: {floor(Value)}")
    
    ggplotly(tooltip = "text", ggplot(
      x,
      aes(
        group = Label,
        color = Label,
        text =  tooltip %>% glue()
      )
    ) +
      geom_point(aes(x = Date, y = Value)) +
      geom_line(aes(x = Date, y = Interpolated, text = NULL)) +
      labs(x = "Date" %>% glue(), y = "Absolute deaths") +
      theme_minimal() +
      theme(legend.title = element_blank()) +
      scale_color_brewer(palette = "Set2")
    )
  })
  
  return(output)
}


renderTableSummary <- function(input) {
  num_format <- function(x) format(x, big.mark = ".", decimal.mark = ",", scientific = F, trim = T, digits = 0)

  output <- renderTable({
    data.summary %>% filter(Regio == input$region) %>%
      mutate(
        `Deaths (any cause)` = num_format(Deaths),
        `Above avg` = num_format(DeathsAboveAvg),
        `Unexpected**` = num_format(DeathsUnexpected), 
        `Reported by RIVM` = num_format(Rivm),
        `Year highest mortality` = YearHighestMort %>% as.character()
      ) %>% select(-Deaths, -DeathsAboveAvg, -DeathsUnexpected, -Rivm, -YearHighestMort)
  })

  
  return(output)
}

renderMapAreas <- function(input) {
  pal <- colorNumeric(
    palette = "YlOrRd", domain = data.mort_spatial$MortalityRate)
  
  last_week <- data.mort_spatial %>% drop_na(MortalityRate) %>% pull(Period) %>% max()
  x2 <- data.mort_spatial %>% filter(Period == last_week)
  
  output <- renderLeaflet({
    labels <- "<strong>{x2$Gemeentenaam}</strong>" %>% glue() %>% lapply(htmltools::HTML)
    leaflet() %>% addTiles() %>%
      addPolygons(
        data = x2,
        fillColor = ~pal(MortalityRate), fillOpacity = 1, stroke = T, 
        color = "white", weight = 1, dashArray = 3,
        layerId = x2$RegioS,
        label = labels,
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto")
      )
  })
  
  return(output)
}

renderTitleTableSummary <- function(input) {
  output <- renderUI({
    region = regions %>% filter(Regio == input$region) %>% pull(Name)
    lastupdated = data.mort_over_time_all %>% filter(Regio == input$region) %>% 
      pull(Date) %>% max(na.rm = T)
    h3("Totals for {region} until {lastupdated}" %>% glue())
  })
  
  return(output)
}

