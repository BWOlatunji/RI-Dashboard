library(shiny)
library(bslib)
library(tidyverse)
library(bsicons)
library(thematic)

library(sf)         
library(leaflet)


source("R/riMapModule.R")
source("R/riOverviewModule.R")

health_care_facilities_geo <-
  read_rds("data/health_care_facilities_geo.rds")

ui <- page_sidebar(
  # Set the CSS theme
  theme = bs_theme(
    bootswatch = "flatly",
    version = 5,
    success = "#036666",
    secondary = "#67B99A",
    default = "white",
    danger = "red",
    "table-color" = "#036666",
    base_font = font_google("Montserrat", local = TRUE)
  ),
  h4(tags$b("Routine Immunization Dashboard")),
  sidebar = sidebar(
    width = 275,
    actionButton("addTripPlan", "Add RI Trip Plan"),
    actionButton("addTripBudget", "Add RI Trip Budget") #,
    #actionButton("remove", "Remove 'Foo' tab")
  ),
  nav_spacer(),
  navset_tab(id = "navTabs",
             nav_panel(value = "CCEs",
               title = p(tags$img(
                 src = "./images/noun-cold-chain-logistics-5729734.svg",
                 width = "20px",height="15px",
                 class = "pull-left"
               ),"Cold Chain Equipment Distribution"), 
               br(),
               div(
                 div(riOverviewUI("riOUI")),
                 div(style = "margin:10px;padding:10px;",
                     riMapUI("mymap"))
               ),
               
             ))
)

server <- function(input, output, session) {
  riMapServer(id = "mymap", dataset = health_care_facilities_geo)
  riOverviewServer("riOUI", dataset = health_care_facilities_geo)
  
  observeEvent(input$addTripPlan, {
    nav_insert(
      "navTabs", target = "CCEs", select = TRUE,
      nav_panel("Trip Plan", "The trip plan would be added here")
    )
  })
  
}


shinyApp(ui, server)
