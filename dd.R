health_care_facilities_geo |> 
  filter(cce_quantity>0 & ri_service_status == 1) |> 
  pull(cce_quantity) |> sum()

health_care_facilities_geo |> st_drop_geometry() |> 
  mutate(ri_service_status = as.numeric(ri_service_status)) |> 
  filter(ri_service_status == 0) |> nrow()


scales::comma(health_care_facilities_geo |>  
                st_drop_geometry() |> 
                mutate(ri_service_status = as.numeric(ri_service_status)) |> 
                filter(ri_service_status == 0) |> 
                nrow())
