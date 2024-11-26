ui <- function(request) {
  fluidPage(tags$head(
    tags$style(type='text/css', 
               ".nav-tabs {font-size: 13px} ")),
    tabsetPanel(
      tabPanel("Sequence Data Generated", module1_UI("Module1")),
      tabPanel("Login to QC metrics dashboard", module2_header_side_body())))
}

