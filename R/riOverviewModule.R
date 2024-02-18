riOverviewUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("value_boxes"))
  )
}

riOverviewServer <- function(id, dataset) {
  moduleServer(
    id,
    function(input, output, session) {
      # 
      country_summary_vals <- reactiveValues(
        cce_count = scales::comma(sum(as.numeric(dataset$cce_quantity))),
        
        state_count = dataset |> 
          filter(cce_quantity>0) |> distinct(state_name) |> nrow(),
        
        ri_service = scales::comma(dataset |> 
                                     st_drop_geometry() |> 
                                     mutate(ri_service_status = as.numeric(ri_service_status)) |> 
                                     filter(ri_service_status == 1) |> 
                                     nrow()),
        
        no_ri_service = scales::comma(dataset |> 
                                        st_drop_geometry() |> 
                                        mutate(ri_service_status = as.numeric(ri_service_status)) |> 
                                        filter(ri_service_status == 0) |> 
                                        nrow())
        
        )
    
      output$value_boxes <- renderUI({
        n_cce <- value_box(
          p(tags$img(style="filter: brightness(0) invert(1);",
            src = "./images/noun-cold-chain-5182398.svg",
            width = "30px",
            class = "pull-left"
          ),"Cold Chain Equipment"),
          paste(country_summary_vals$cce_count, "CCEs"),
          paste("Across", country_summary_vals$state_count, "states in Nigeria"),
          theme = "primary"
        )
        
        ri_service <- value_box(
          p(tags$img(style="filter: brightness(0) invert(1);",
            src = "./images/vaccination.svg",
            width = "30px",
            class = "pull-left"
          ),"Routine Immunization(RI)"),
          paste(country_summary_vals$ri_service, " CCEs"),
          tags$p(paste(
            " with RI services"
          )),
          theme = "success"
        )
       
        no_ri_service <- value_box(
          p(tags$img(style="filter: brightness(0) invert(1);",
            src = "./images/vaccination.svg",
            width = "30px",
            class = "pull-left"
          ),"Routine Immunization(RI)"),
          paste0(country_summary_vals$no_ri_service, " CCEs "),
          tags$p(paste(
            " with no RI services"
          )),
          theme = "danger"
        )

        
        
        layout_columns(class = "mb-0", n_cce, ri_service, no_ri_service)
      })
      
    }
  )
}


