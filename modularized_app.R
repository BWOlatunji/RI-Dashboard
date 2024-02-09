library(shiny)
library(bslib)
library(tidyverse)
library(plotly)
library(bsicons)
library(thematic)
library(leaflet)
library(sf)         # Simple Features
library(nngeo)      # Nearest Neighbors

source("R/riMapUI.R")
source("R/riOverviewUI.R")

health_care_facilities_geo <-
  read_rds("data/health_care_facilities_geo.rds")

ui <- page_fluid(
  # Set the CSS theme
  theme = bs_theme(bootswatch = "flatly",
                   version = 5,
                   success = "#036666",
                   danger = "#99E2B4",
                   "table-color" = "#036666",
                   base_font = font_google("Montserrat", local = TRUE)),
  
  
  title = "Cold Chain Equipment Distribution Dashboard", 
  h1("RI - Cold Chain Equipment Distribution Dashboard"),hr(),
              riOverviewUI("riOUI"), 
              riMapUI("mymap")
)

server <- function(input, output, session) {
  riMapServer(id = "mymap", dataset = health_care_facilities_geo)
  riOverviewServer("riOUI", dataset = health_care_facilities_geo)
}


shinyApp(ui, server)
