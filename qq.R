
# * Getting Major Highways ----

nigeria_bbox <- getbb("Nigeria")


nigeria_highways_sf <- opq(nigeria_bbox) %>%
  add_osm_feature(
    key   = "highway", 
    value = c("motorway", "primary", "motorway_link", "primary_link")
  ) %>%
  osmdata_sf() 


nigeria_highways_sf %>% write_rds("data/nigeria_highways_sf.rds")

nigeria_highways_sf <- read_rds("data/nigeria_highways_sf.rds")

mapview(nigeria_highways_sf$osm_lines)

# * Getting Smaller roads  -----

nigeria_medium_streets_sf <- opq(nigeria_bbox) %>%
  add_osm_feature(
    key   = "highway", 
    value = c("secondary", "tertiary", "secondary_link", "tertiary_link")
  ) %>%
  osmdata_sf()

nigeria_medium_streets_sf %>% write_rds("data/nigeria_medium_streets_sf.rds")

nigeria_medium_streets_sf <- read_rds("data/nigeria_medium_streets_sf.rds")

# * Visualization ----

mapview(
  nigeria_medium_streets_sf$osm_lines, 
  color = "yellow",
  layer.name = "Streets"
) +
  mapview(
    nigeria_highways_sf$osm_lines,
    layer.name = "Highways",
    color = "purple"
  )

# 2.0 CUSTOMERS & WAREHOUSES ----

# * Customer Data ----

hcf_without_cces <- health_care_facilities_geo |> 
  filter(cce_available == "0") 


# * Warehouse Data ----

hcf_with_cces <- health_care_facilities_geo |> 
  filter(cce_available == "1") 

hcf_with_cces <- read_rds("data/hcf_with_cces.rds") %>%
  rowid_to_column(var = "distributor_id")

# * Visualize ----
mapview(
  nigeria_medium_streets_sf$osm_lines, 
  color      = "green",
  layer.name = "Streets",
  map.types  = "CartoDB.DarkMatter",
  lwd        = 0.5 
) +
  mapview(
    nigeria_highways_sf$osm_lines,
    layer.name = "Highways",
    color      = "purple",
    lwd        = 2
  ) +
  mapview(
    hcf_without_cces,
    col.region = "cyan",
    color      = "white",
    layer.name = "Customers",
    cex        = 12
  ) +
  mapview(
    hcf_with_cces,
    col.region = "magenta",
    color      = "white",
    layer.name = "Warehouses",
    cex        = 20
  )

# 3.0 NEAREST NEIGHBORS ----
# * Alternatively we can use sfnetworks
# * I'm going to use nngeo

# * Getting Nearest Neighbors with nngeo ----

network_ids <- st_nn(
  x = hcf_with_cces,
  y = hcf_without_cces,
  # k = 5,
  k = nrow(hcf_without_cces),
  progress = T
)


network_lines_sf <- st_connect(
  x   = hcf_with_cces,
  y   = hcf_without_cces,
  ids = network_ids
)



mapview(
  nigeria_medium_streets_sf$osm_lines, 
  color      = "green",
  layer.name = "Streets",
  map.types  = "CartoDB.DarkMatter",
  lwd        = 0.5 
) +
  mapview(
    nigeria_highways_sf$osm_lines,
    layer.name = "Highways",
    color      = "purple",
    lwd        = 2
  ) +
  mapview(
    hcf_without_cces,
    col.region = "cyan",
    color      = "white",
    layer.name = "Customers",
    cex        = 12
  ) +
  mapview(
    hcf_with_cces,
    col.region = "magenta",
    color      = "white",
    layer.name = "Warehouses",
    cex        = 20
  ) +
  mapview(
    network_lines_sf,
    color      = "yellow"
  )

# * Approximate Shortest Path ----

nodes_tbl <- network_ids %>%
  enframe(
    name  = "distributor_id",
    value = "customer_id"
  ) %>%
  unnest(customer_id)

shortest_network_sf <- network_lines_sf %>%
  st_bind_cols(nodes_tbl) %>%
  mutate(len = st_length(geometry)) %>%
  relocate(len, .after = customer_id) %>%
  
  group_by(customer_id) %>%
  filter(len == min(len)) %>%
  ungroup()

mapview(
  nigeria_medium_streets_sf$osm_lines,
  color      = "green",
  layer.name = "Streets",
  map.types  = "CartoDB.DarkMatter",
  lwd        = 0.5
) +
  mapview(
    nigeria_highways_sf$osm_lines,
    layer.name = "Highways",
    color      = "purple",
    lwd        = 2
  ) +
  mapview(
    hcf_without_cces,
    col.region = "cyan",
    color      = "white",
    layer.name = "Customers",
    cex        = 12
  ) +
  mapview(
    hcf_with_cces,
    col.region = "magenta",
    color      = "white",
    layer.name = "Warehouses",
    cex        = 20
  ) +
  mapview(
    shortest_network_sf,
    color      = "yellow",
    layer.name = "Shortest Network"
  )

# * Defining the Trip Points ----

nigeria_route_points_sf <- hcf_with_cces %>%
  
  bind_rows(hcf_without_cces) %>%
  select(type, distributor_id, customer_id, everything()) %>%
  
  # Adding in the distributor that the customer belongs to
  left_join(
    shortest_network_sf %>% 
      select(distributor_id, customer_id) %>%
      as_tibble() %>%
      rename(distributor_to = distributor_id) %>%
      select(-geometry),
    by   = "customer_id"
  ) %>%
  
  # Cleanup distributor_to
  mutate(distributor_to = ifelse(is.na(distributor_to), distributor_id, distributor_to)) %>%
  mutate(distributor_to = as.factor(distributor_to))

mapview(
  nigeria_route_points_sf,
  zcol       = "distributor_to",
  layer.name = "Distributor Network"
)

# 4.0 OSM ROUTES API ----

# * Getting 1 route ----
route_1_list <- nigeria_route_points_sf %>%
  filter(distributor_to == 1) %>%
  osrmTrip()

route_1_list[[1]]$summary

mapview(route_1_list[[1]]$trip)



# * Mapping to many routes ----

warehouse_trips_tbl <- nigeria_route_points_sf %>%
  group_by(distributor_to) %>%
  group_nest() %>%
  mutate(trip = map(data, .f = osrmTrip))

warehouse_trips_tbl$trip[[1]]

warehouse_trips_sf <- warehouse_trips_tbl %>%
  
  # Double unnest
  select(-data) %>%
  unnest(trip) %>%
  unnest(trip) %>%
  
  # Get first item
  group_by(distributor_to) %>%
  slice(1) %>%
  ungroup() %>%
  
  # Unnest sf object and convert to sf
  unnest(trip) %>%
  st_as_sf()

# * Visualize the Routes ----

mapview(
  hcf_without_cces,
  col.region = "cyan",
  color      = "white",
  layer.name = "Customers",
  cex        = 12,
  map.types  = "CartoDB.DarkMatter"
) +
  mapview(
    hcf_with_cces,
    col.region = "magenta",
    color      = "white",
    layer.name = "Warehouses",
    cex        = 20
  ) +
  mapview(
    warehouse_trips_sf,
    zcol = "distributor_to",
    color = tidyquant::palette_dark()[c(1,2,4)],
    layer.name = "Trip"
  )

# 5.0 COSTS ----

# * Estimating trip cost ----

warehouse_trips_tbl %>%
  # Double unnest
  select(-data) %>%
  unnest(trip) %>%
  unnest(trip) %>%
  
  # Get the 2nd item
  group_by(distributor_to) %>%
  slice(2) %>%
  ungroup() %>%
  
  # Trick: Unnest wider
  unnest_wider(trip) %>%
  
  # Add our costs
  mutate(driver_cost_per_trip = 500) %>%
  mutate(fuel_cost_per_km = 12) %>%
  mutate(total_cost  = distance * fuel_cost_per_km + driver_cost_per_trip)


