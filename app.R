library(shiny)
library(bslib)
library(tidyverse)
library(bsicons)
library(leaflet)
library(DT)
library(sf)         # Simple Features
library(nngeo)      # Nearest Neighbors

health_care_facilities_geo <- read_rds("data/health_care_facilities_geo.rds")


ui <- page_fillable(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  theme = bs_theme(version = 5),
  lang = "en",
  tags$span(
    tags$img(
      src = "ngr_logo.png",
      width = "46px",
      height = "auto",
      class = "me-3",
      alt = "Nigeria Flag logo"
    ),
    h2("Routine Immunization Dashboard")
  ),
  div(
    "RI overview",
    uiOutput("value_boxes"),
    layout_columns(
      col_widths = c(8, 4),
      card(
        full_screen = TRUE,
        card_header(uiOutput("selected_state")),
        leafletOutput(outputId = "map_plot")
      ),
      div(
        HTML('<div class="col-xxl-4 col-md-6">
              <div class="card info-card sales-card">

                <div class="card-body">
                  <h5 class="card-title">Sales <span>| Today</span></h5>

                  <div class="d-flex align-items-center">
                    <div class="card-icon rounded-circle d-flex align-items-center justify-content-center">
                      <i class="bi bi-cart"></i>
                    </div>
                    <div class="ps-3">
                      <h6>145</h6>
                      <span class="text-success small pt-1 fw-bold">12%</span> <span class="text-muted small pt-2 ps-1">increase</span>

                    </div>
                  </div>
                </div>

              </div>
            </div>'),
        uiOutput("state_functional_status_summary")
      ) 
      
    )
  )
)



server <- function(input, output, session) {
  
  country_summary_vals <- reactiveValues(
    cce_count = scales::comma(sum(as.numeric(health_care_facilities_geo$cce_quantity))),
    
    state_count = health_care_facilities_geo |> 
      filter(cce_quantity>0) |> distinct(state_name) |> nrow(),
    
    ri_service = scales::comma(health_care_facilities_geo |> 
                                 filter(cce_quantity>0 & ri_service_status == 1) |> 
                                 pull(cce_quantity) |> sum()),
    
    no_ri_service = scales::comma(health_care_facilities_geo |> 
                                    filter(cce_quantity>0 & ri_service_status == 0) |> 
                                    pull(cce_quantity) |> sum()))
  
  output$value_boxes <- renderUI({
    n_cce <- value_box(
      "A TOTAL OF",
      paste(country_summary_vals$cce_count, "CCEs"),
      paste("Across", country_summary_vals$state_count, "states in Nigeria"),
      theme = "primary",
      showcase = icon("hospital")
    )
    
    ri_service <- value_box(
      "RI Service",
      paste(country_summary_vals$ri_service, " CCEs"),
      tags$p(paste(
        " with RI services"
      )),
      theme = "success",
      showcase = icon("syringe")
    )
    
    no_ri_service <- value_box(
      "RI SERVICE",
      paste0(country_summary_vals$no_ri_service, " CCEs "),
      tags$p(paste(
        " with no RI services"
      )),
      theme = "danger",
      showcase = icon("syringe")
    )
    
    layout_columns(class = "mb-0", n_cce, ri_service, no_ri_service)
  })
  
  map_df <- reactive({
    df <- health_care_facilities_geo |>
      filter(cce_quantity>0) |> 
      group_by(state_name) |> 
      summarise(num_cces = sum(as.numeric(cce_quantity)), 
                cce_ri = sum(as.numeric(ri_service_status == "1")),
                cce_no_ri = sum(as.numeric(ri_service_status == "0")),
                geometry = st_centroid(st_combine(geometry))) |> 
      mutate(label=paste0("<center>",
                          '<h2>',toupper(state_name),"</h2>",
                          "<hr>",
                          "</center>",
                          "<span><b>No. of CCEs: </b></span>",num_cces,"</br>", 
                          "<span><b>CCEs with RI Service: </b></span>",cce_ri,"</br>",
                          "<span><b>CCEs without RI Service: </b></span>",cce_no_ri, 
                          "<br>"))
    
    # Extract latitude and longitude
    coordinates <- st_coordinates(df)
    
    # Add latitude and longitude columns to the data frame
    df <- cbind(df, coordinates)
    
    # Rename the columns for clarity
    colnames(df)[6:7] <- c("longitude", "latitude")
    df
    
  })
  
  output$map_plot <- renderLeaflet({
    # Create a leaflet map
    leaflet()|>
      addTiles()|>  # Add a base layer
      addCircleMarkers(data = map_df(),
                       label =~lapply(label, htmltools::HTML),
                       fillColor = "green",
                       fillOpacity = 1,
                       stroke = F
      )
  })
  
  
  observeEvent(input$map_plot_marker_click, {
    # Format the values to have 6 decimal places without rounding
    # and convert the formatted strings back to numeric if needed
    lat <- round(input$map_plot_marker_click$lat, 6)
    lng <- round(input$map_plot_marker_click$lng, 6)
    
    # In this code, I'm using the between function to check if the latitude and longitude
    # are within a small range around the target values. The range (in this case, ±0.000001)
    # is chosen based on your requirement for 6 decimal places precision without rounding.
    
    clicked_loc <- map_df() |>
      filter(between(latitude, lat - 0.000001, lat + 0.000001) &
               between(longitude, lng - 0.000001, lng + 0.000001)) |>
      select(state_name) |>
      st_drop_geometry() |>
      pull()
    
    # Check if clicked_loc is not empty before proceeding
    if (length(clicked_loc) == 0) {
      return()
    }
    
    # Display the clicked state in the UI
    output$selected_state <- renderUI({
      h2(style = "color: green;text-transform: uppercase;", clicked_loc)
    })
    
    output$state_functional_status_summary <- renderUI({
      dt <- health_care_facilities_geo|>
        filter(state_name == clicked_loc)|>
        count(functional_status) |> 
        st_drop_geometry() |> 
        select(functional_status, n)|>
        set_names(c("Functional Status", "Count"))
      
      # Assuming you want the count for "Functional" status
      count_functional <- scales::comma(as.numeric(filter(dt, `Functional Status` == "Functional")$Count))
      count_nf <- scales::comma(as.numeric(filter(dt, `Functional Status` == "Non Functional")$Count))
      count_ndal <- scales::comma(as.numeric(filter(dt, `Functional Status` == "Non Functional/Dilapidated/Abandoned")$Count))
      count_nfnc <- scales::comma(as.numeric(filter(dt, `Functional Status` == "Non Functional/Newly Commissioned")$Count))
      count_nfuc <- scales::comma(as.numeric(filter(dt, `Functional Status` == "Non Functional/Under Construction/Renovation")$Count))
      count_unknown <- scales::comma(as.numeric(filter(dt, `Functional Status` == "Unknown")$Count))
      
        v_cf <- value_box(
          "Number of State CCEs:",
          count_functional,
          "Functional Status: Functional"
        )
        
        v_cnf <- value_box(
          "Number of State CCEs:",
          count_nf,
          "Functional Status: Non Functional"
        )
        
        v_cndal <- value_box(
          "Number of State CCEs:",
          count_ndal,
          "Functional Status: Non Functional/Dilapidated/Abandoned"
        )
        
        v_cnfnc <- value_box(
        "Number of State CCEs:",
         count_nfnc,
        "Functional Status: Non Functional/Newly Commissioned"
        )
        
        v_cnfuc <- value_box(
          "Number of State CCEs:",
          count_nfuc,
          "Functional Status: Non Functional/Under Construction/Renovation"
        )
        
        v_unknown <- value_box(
          "Number of State CCEs:",
          count_unknown,
          "Functional Status: Unknown"
        )
        
        
        div(v_cf, v_cnf,v_cndal, v_cnfnc, v_cnfuc,v_unknown)
    
      
    })
    
    # get data based on state name
    st_map_data <- df <- health_care_facilities_geo |>
      filter(state_name == clicked_loc) |>
      mutate(label = paste0("<center>",
                            '<h2>', toupper(name), "</h2>",
                            "<hr>",
                            "</center>",
                            "<span><b>RI Service: </b></span>", if_else(ri_service_status == "1", "Available", "Not Available"), "</br>",
                            "<span><b>Functional Status: </b></span>", functional_status, "</br>",
                            "<span><b>CCE Service: </b></span>", if_else(cce_available == "1", "Available", "Not Available"),
                            "<br>"))
    
    leafletProxy("map_plot", data = st_map_data)|>
      clearMarkerClusters()|>
      clearShapes()|>
      clearMarkers()|>
      clearControls()|>
      fitBounds(lng1 = min(st_map_data$longitude),
                lat1 = min(st_map_data$latitude),
                lng2 = max(st_map_data$longitude),
                lat2 = max(st_map_data$latitude)) |> 
      addMarkers(lng = ~longitude,
                 lat = ~latitude,
                 popup = ~label,
                 clusterOptions = markerClusterOptions(),
                 layerId = ~global_id)
    
  })
  
  
}

shinyApp(ui, server)

