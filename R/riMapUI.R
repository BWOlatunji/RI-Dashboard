riMapUI <- function(id) {
  ns <- NS(id)
  tagList(
    card(
      full_screen = TRUE,
      card_header(uiOutput(ns("selected_state"))),
                     leafletOutput(outputId = ns("map_plot"))
    )
  )
}

riMapServer <- function(id, dataset) {
  moduleServer(
    id,
    function(input, output, session) {
      
      # map data
      map_tbl <- reactive({
        df <- dataset |>
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
          setView(lng = 9.072264,lat = 7.491302,zoom = 10) |> 
          fitBounds(lng1 = 3,
                    lat1 = 4,
                    lng2 = 14,
                    lat2 = 13) |> 
          addCircleMarkers(data = map_tbl(),
                           label =~lapply(label, htmltools::HTML),
                           fillColor = "#036666",
                           radius = 6,
                           fillOpacity = 1,
                           stroke = F
          )
      }) |> 
        bindCache(map_tbl())
      
      
      observe({
        # Format the values to have 6 decimal places without rounding
        # and convert the formatted strings back to numeric if needed
        lat <- round(input$map_plot_marker_click$lat, 6)
        lng <- round(input$map_plot_marker_click$lng, 6)
        
        # In this code, I'm using the between function to check if the latitude and longitude
        # are within a small range around the target values. The range (in this case, ±0.000001)
        # is chosen based on your requirement for 6 decimal places precision without rounding.
        
        clicked_loc <- map_tbl() |>
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
        
        # get data based on state name
        st_map_data <- df <- dataset |>
          filter(state_name == clicked_loc) |>
          mutate(label = paste0("<center>",
                                '<h6>', toupper(name), "</h6>",
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
        
      }) |> 
        bindEvent(input$map_plot_marker_click)
      
    }
  )
}
