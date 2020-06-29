#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(leaflet)


notebookPage <- function(page) {
    return(fluidPage(tags$iframe(
        srcdoc = includeHTML(page),
        frameborder = "0",
        style = "overflow:hidden;height:calc(100vh - 85px);width:100%",
        height = "100%",
        width = "100%"
    )))
}

dashboardTab <- tabPanel("Dashboard",
    fluidRow(
        column(width = 8,
               h3("Corona victims"), 
               plotlyOutput("plot.emort_over_time", height = 200),
               
               h3("Mortality trends"),
               plotlyOutput("plot.mort_over_time", height = 200),
               
               uiOutput("title.table.sums"), 
               tableOutput("table.sums"),
               
        ),
        column(width = 4,
               h3("Map"),
               h5("Click the map to see data for that specific region."),
               leafletOutput("map.areas", height = 600),
        )
    )
)

# Define UI for application that draws a histogram
shinyUI(
    navbarPage(
        title = "Corona Dashboard",
        tabPanel("Dashboard", dashboardTab),
        navbarMenu("Methodology",
            "----",
            "Data",
            tabPanel(
                "Netherlands",
                notebookPage("notebooks/data.nb.html")
            ),
            tabPanel(
                "Regions",
                notebookPage("notebooks/data.spatial.nb.html")
            ),
            tabPanel(
                "Air data",
                notebookPage("notebooks/dataproviders/air.nb.html")
            ),
            tabPanel(
                "Temperature data",
                notebookPage("notebooks/dataproviders/temperature.nb.html")
            ),
            tabPanel(
                "RIVM",
                notebookPage("notebooks/dataproviders/rivm.nb.html")
            ),
            "----",
            "Training & predicting",
            tabPanel(
                "Training",
                notebookPage("notebooks/train.nb.html")
            ),
            tabPanel(
                "Predictions",
                notebookPage("notebooks/predict.nb.html")
            ),
            "----",
            "Postprocessing",
            tabPanel("Plotting data",
                notebookPage("notebooks/plotdata.nb.html")
            )
        )
    )
)