#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(tmap)
library(httr)
library(sf)
library(ggalt)
library(tidyverse)
library(glue)
library(leaflet)

source("plots.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    input2 <- reactiveValues(region = "NL")
    
    # months <- data.mort_over_time_all %>% filter(Interval == "month") %>% drop_na("MortalityRate") %>% 
    #     distinct(Period) %>% pull("Period")
    # names(months) <- months %>% map(function(x) month.name[x])
    # 
    # output$input.period <- renderUI({ selectInput(
    #     "period",
    #     label = "Period",
    #     choices = months,
    #     selectize = FALSE
    # )})

    output$title.table.sums <- renderTitleTableSummary(input2)
    output$table.sums <- renderTableSummary(input2)
    
    output$plot.mort_over_time <- renderPlotMortOverTime(input2)
    output$plot.emort_over_time <- renderPlotExcessiveMortOverTime(input2)
    
    
    # output$map.areas <- renderMapAreas(input)
    output$map.areas <- renderMapAreas(input2)
    
    observeEvent(input$map.areas_shape_click, { # update the location selectInput on map clicks
        p <- input$map.areas_shape_click
        proxy <- leafletProxy("map.areas")
        
        if (p$id == "highlight") {
            proxy %>% removeShape("highlight")
            input2$region <- "NL"
        } else {
            input2$region <- p$id
            selected <- data.mort_spatial %>% filter(RegioS == p$id, Period == max(data.mort_spatial$Period))
            proxy %>% addPolygons(
                data = selected, stroke = T, weight = 2, fillColor = "black",  fillOpacity = 0.1, color = "red", layerId = "highlight"
            )      
        }
    })
    
})
