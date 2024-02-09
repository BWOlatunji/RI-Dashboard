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
                                     filter(cce_quantity>0 & ri_service_status == 1) |> 
                                     pull(cce_quantity) |> sum()),
        
        no_ri_service = scales::comma(dataset |> 
                                        filter(cce_quantity>0 & ri_service_status == 0) |> 
                                        pull(cce_quantity) |> sum())
        
        )
      
      output$value_boxes <- renderUI({
        n_cce <- value_box(
          "Cold Chain Equipment",
          paste(country_summary_vals$cce_count, "CCEs"),
          paste("Across", country_summary_vals$state_count, "states in Nigeria"),
          theme = "primary",
          showcase = icon("hospital")
        )
        
        ri_service <- value_box(
          "Routine Immunization(RI)",
          paste(country_summary_vals$ri_service, " CCEs"),
          tags$p(paste(
            " with RI services"
          )),
          theme = "success",
          showcase = icon("syringe")
        )
        
        no_ri_service <- value_box(
          "Routine Immunization(RI)",
          paste0(country_summary_vals$no_ri_service, " CCEs "),
          tags$p(paste(
            " with no RI services"
          )),
          theme = "danger",
          showcase = icon("syringe")
        )
        layout_columns(class = "mb-0", n_cce, ri_service, no_ri_service)
      })
      
    }
  )
}
