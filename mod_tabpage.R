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

# Set the default theme for ggplot2 plots
ggplot2::theme_set(ggplot2::theme_minimal())

# Apply the CSS used by the Shiny app to the ggplot2 plots
thematic_shiny()

ui <- page_fluid(
  # Set the CSS theme
  theme = bs_theme(bootswatch = "flatly",
                   version = 5,
                   success = "#036666",
                   danger = "#99E2B4",
                   "table-color" = "#036666",
                   base_font = font_google("Montserrat", local = TRUE)),
  
  
  h1("Routine Immunization Dashboard"),
  
  page_navbar(
    nav_panel(title = "Cold Chain Equipment Location Map", class = "h6 text-success",
              riOverviewUI("riOUI"), 
              riMapUI("mymap"), div()
    ),
    nav_panel(title = "RI Trip Plan", p("Under construction")),
    nav_panel("RI Trip Budget", p("Third page content."))
  )
)

server <- function(input, output, session) {
  riMapServer(id = "mymap", dataset = health_care_facilities_geo)
  riOverviewServer("riOUI", dataset = health_care_facilities_geo)
}


shinyApp(ui, server)
