riMapUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(uiOutput(ns("selected_state"))),
    layout_columns(
      class = "mb-0",
      col_widths = c(9, 3),
      leafletOutput(outputId = ns("map_plot")),
      div(
        class = "panel-body bg_color text_color",
        h4("State CCE Functionality"),
        p(
          "Below is a breakdown of the functionality status of the Cold Chain Equipments in each state."
        ),
        uiOutput(ns("cards"))
      )
    )
  )
}

riMapServer <- function(id, dataset) {
  moduleServer(id,
               function(input, output, session) {
                 # map data
                 map_tbl <- reactive({
                   df <- dataset |>
                     filter(cce_quantity > 0) |>
                     group_by(state_name) |>
                     summarise(
                       num_cces = sum(as.numeric(cce_quantity)),
                       cce_ri = sum(as.numeric(ri_service_status == "1")),
                       cce_no_ri = sum(as.numeric(ri_service_status == "0")),
                       geometry = st_centroid(st_combine(geometry))
                     ) |>
                     mutate(
                       label = paste0(
                         "<center>",
                         '<h2>',
                         toupper(state_name),
                         "</h2>",
                         "<hr>",
                         "</center>",
                         "<span><b>No. of CCEs: </b></span>",
                         num_cces,
                         "</br>",
                         "<span><b>CCEs with RI Service: </b></span>",
                         cce_ri,
                         "</br>",
                         "<span><b>CCEs without RI Service: </b></span>",
                         cce_no_ri,
                         "<br>"
                       )
                     )
                   
                   # Extract latitude and longitude
                   coordinates <- st_coordinates(df)
                   
                   # Add latitude and longitude columns to the data frame
                   df <- cbind(df, coordinates)
                   
                   # Rename the columns for clarity
                   colnames(df)[6:7] <- c("longitude", "latitude")
                   df
                   
                 })
                 
                 clickedState <- reactiveVal(NULL)
                 
                 output$map_plot <- renderLeaflet({
                   # Create a leaflet map
                   leaflet() |>
                     addTiles() |>  # Add a base layer
                     setView(lng = 9.072264,
                             lat = 7.491302,
                             zoom = 15) |>
                     fitBounds(
                       lng1 = 2.68,
                       lat1 = 4.07,
                       lng2 = 14.68,
                       lat2 = 13.89
                     ) |>
                     addCircleMarkers(
                       data = map_tbl(),
                       label =  ~ lapply(label, htmltools::HTML),
                       fillColor = "#036666",
                       radius = 10,
                       fillOpacity = 1,
                       stroke = F
                     )
                 }) |>
                   bindCache(map_tbl())
                 
                 # Define card content generation function
                 create_card_content <- function(row) {
                   # Extract information from the row
                   name <- row$`Functional Status`
                   Count <- row$Count
                   div(
                     class = "card",
                     style = "width: 12rem;margin:5px;",
                     div(
                       class = "card-body",style = "height: 7rem;background-color:#99E2B4;font-size:12px;color:white;",
                       h5(class = "card-title", name),
                       p(
                         class = "card-text",
                         Count
                       )
                     )
                   )
                 }
                 
                 observe({
                   # Format the values to have 6 decimal places without rounding
                   # and convert the formatted strings back to numeric
                   lat <- round(input$map_plot_marker_click$lat, 6)
                   lng <- round(input$map_plot_marker_click$lng, 6)
                   
                   # In this code, I'm using the between function to check if the latitude and longitude
                   # are within a small range around the target values. 
                   # The range, in this case, ±0.000001 is chosen based on our requirement 
                   # for 6 decimal places precision without rounding.
                   
                   clicked_state <- map_tbl() |>
                     filter(
                       between(latitude, lat - 0.000001, lat + 0.000001) &
                         between(longitude, lng - 0.000001, lng + 0.000001)
                     ) |>
                     select(state_name) |>
                     st_drop_geometry() |>
                     pull()
                   
                   # Check if clicked_state is not empty before proceeding
                   if (length(clicked_state) == 0) {
                     return()
                   }
                   
                   clickedState(clicked_state)
                   
                   dt <- dataset |>
                     filter(state_name == clickedState()) |>
                     count(functional_status) |>
                     st_drop_geometry() |>
                     select(functional_status, n) |>
                     set_names(c("Functional Status", "Count"))
                   
                   output$cards <- renderUI({
                     map(1:nrow(dt), function(i) {
                       create_card_content(dt[i,])
                     })
                   })
                   # Display the clicked state in the UI
                   output$selected_state <- renderUI({
                     h4(style = "color: green;text-transform: uppercase;margin:3px;", 
                        clickedState())
                   })
                   
                   # get data based on state name
                   st_map_data <- dataset |>
                     filter(state_name == clickedState()) |>
                     mutate(
                       label = paste0(
                         "<center>",
                         '<h6>',
                         toupper(name),
                         "</h6>",
                         "<hr>",
                         "</center>",
                         "<span><b>RI Service: </b></span>",
                         if_else(ri_service_status == "1", "Available", "Not Available"),
                         "</br>",
                         "<span><b>Functional Status: </b></span>",
                         functional_status,
                         "</br>",
                         "<span><b>CCE Service: </b></span>",
                         if_else(cce_available == "1", "Available", "Not Available"),
                         "<br>"
                       )
                     )
                   
                   
                   leafletProxy("map_plot", data = st_map_data) |>
                     clearMarkerClusters() |>
                     clearShapes() |>
                     clearMarkers() |>
                     clearControls() |>
                     fitBounds(
                       lng1 = min(st_map_data$longitude),
                       lat1 = min(st_map_data$latitude),
                       lng2 = max(st_map_data$longitude),
                       lat2 = max(st_map_data$latitude)
                     ) |>
                     addMarkers(
                       lng = ~ longitude,
                       lat = ~ latitude,
                       popup = ~ label,
                       clusterOptions = markerClusterOptions(),
                       layerId = ~ global_id
                     )
                   
                 }) |>
                   bindEvent(input$map_plot_marker_click)
                 
                 
               })
}
