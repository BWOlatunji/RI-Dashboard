info_card <- function(title, value, sub_value,
                      main_icon = "chart-line", sub_icon = "arrow-up",
                      bg_color = "default", text_color = "default", sub_text_color = "success") {
  
  div(
    class = "panel panel-default",
    style = "padding: 0px;",
    div(
      class = str_glue("panel-body bg-{bg_color} text-{text_color}"),
      p(class = "pull-right", icon(class = "fa-4x", main_icon)),
      h4(title),
      h5(value),
      p(
        class = str_glue("text-{sub_text_color}"),
        icon(sub_icon),
        tags$small(sub_value)
      )
    )
  )
  
}

tags$img(src = "./images/logo.svg", width = "99px")

div(class = "panel panel-default",
    style = "padding: 0px;",
    div(
      class = str_glue("panel-body bg-{bg_color} text-{text_color}"),
      tags$img(
        src = src_url,
        width = "99px",
        class = "pull-right"
      ),
      h2(title),
      h3(value),
      p(class = str_glue("text-{sub_text_color}"),
        h5(sub_value))
    ))

