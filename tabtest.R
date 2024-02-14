

  ui <- page_sidebar(
    sidebar = sidebar(width = 275, 
                      actionButton("add", "Add 'Dynamic' tab"),
                      actionButton("remove", "Remove 'Foo' tab")),
    nav_spacer(),
    navset_tab(
      id = "tabs",
      nav_panel("Hello", "hello"),
      nav_panel("Foo", "foo"),
      nav_panel("Bar", "bar tab")
    )
  )
  server <- function(input, output) {
    observeEvent(input$add, {
      nav_insert(
        "tabs", target = "Bar", select = TRUE,
        nav_panel("Dynamic", "Dynamically added content")
      )
    })
    observeEvent(input$remove, {
      nav_remove("tabs", target = "Foo")
    })
  }
  shinyApp(ui, server)