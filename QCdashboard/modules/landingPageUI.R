module1_UI <- function(id) {
  ns <- NS(id)
  tagList(
      shinyjs::useShinyjs(),
      sidebarLayout(
        sidebarPanel(width=2,
                     radioButtons(ns("option"),"Show metrics by month",choices = c('Yes','No'),
                                                           selected = "No",
                                                           inline = T),
                     pickerInput(inputId = ns("year"), label = "Year",choices = NULL,selected = NULL,multiple = T,
                                                          options = pickerOptions(actionsBox = TRUE,title = "Search year",liveSearch = TRUE,
                                                                                  liveSearchPlaceholder="Select year",liveSearchStyle="contains",
                                                                                  selectedTextFormat = 'count > 1',
                                                                                  countSelectedText = "{0} of {1} date selected"
                                                          ),choicesOpt = list(style = rep(("color: black; background: white"),500))),
                     pickerInput(inputId = ns("epoch"), label = "Epoch",choices = NULL,multiple = T,
                                                          options = pickerOptions( actionsBox = TRUE,title = "monthly or quarterly",liveSearch = TRUE,
                                                                                   liveSearchPlaceholder="Select quarter/month", liveSearchStyle="contains", 
                                                                                   selectedTextFormat = 'count > 1',
                                                                                   countSelectedText = "{0} of {1}  epoch selected"),
                                                          choicesOpt = list(style = rep(("color: black; background: white"),500))),
                     pickerInput(inputId = ns("platform"), label = "Platform(s)", choices = NULL,selected = NULL,multiple = F,
                                                          options = pickerOptions(actionsBox = TRUE,title = "Search platform",
                                                                                  liveSearch = TRUE,liveSearchPlaceholder="Select platform", liveSearchStyle="contains",
                                                                                  selectedTextFormat = 'count > 1', countSelectedText = "{0} of {1} platform(s)"
                                                          ),choicesOpt = list(style = rep(("color: black; background: white"),500))),
                     div(id=ns("application_parent"),pickerInput(inputId = ns("application"),label = "Application",choices = NULL,selected = NULL,multiple = T,
                                                                                          options = pickerOptions(actionsBox = TRUE,title = "Select app",liveSearch = TRUE,
                                                                                                                  liveSearchPlaceholder="Search keyword",
                                                                                                                  liveSearchStyle="contains",selectedTextFormat = 'count > 1',
                                                                                                                  countSelectedText = "{0} of {1} app selected"),
                                                                                          choicesOpt = list(style = rep(("color: black; background: white"),500)))),
                     pickerInput(inputId = ns("metrics"), label = "Metrics(s)", choices = NULL,selected = NULL,multiple = F,
                                                          options = pickerOptions(actionsBox = TRUE,title = "Search metrics",
                                                                                  liveSearch = TRUE,liveSearchPlaceholder="Select metrics", liveSearchStyle="contains",
                                                                                  selectedTextFormat = 'count > 1', countSelectedText = "{0} of {1} metric"
                                                          ),choicesOpt = list(style = rep(("color: black; background: white"),500))),
                     radioButtons(ns("site"),"Site",choices = c("Merge", 'Split'),
                                                           selected = NULL, inline = T),
                     radioButtons(ns("more_plot"),"Additional plots",choices = c("Yes", 'No'),
                                                           selected = "No", inline = T),
                     radioButtons(ns("more_plots_opt"),"Plots",choices = c("Machine", 'Lab', 'Project'),
                                                           selected = NULL, inline = T),
                     div(id=ns("instrument_parent"),
                                                  pickerInput(inputId = ns("instrument"), label = "Instrument", choices = NULL,selected = NULL,multiple = T,
                                                              options = pickerOptions(actionsBox = TRUE,title = "Search instrument",
                                                                                      liveSearch = TRUE,liveSearchPlaceholder="Select instrument", liveSearchStyle="contains",
                                                                                      selectedTextFormat = 'count > 1', countSelectedText = "{0} of {1} instrument(s)"
                                                              ),choicesOpt = list(style = rep(("color: black; background: white"),500)))),
                     div(id=ns("lab_parent"),
                                                  pickerInput(inputId = ns("lab"), label = "Select lab", choices = NULL,selected = NULL,multiple = T,
                                                              options = pickerOptions(actionsBox = TRUE,title = "Search lab",
                                                                                      liveSearch = TRUE,liveSearchPlaceholder="Select lab", liveSearchStyle="contains",
                                                                                      selectedTextFormat = 'count > 1', countSelectedText = "{0} of {1} lab(s)"
                                                              ),choicesOpt = list(style = rep(("color: black; background: white"),500)))),
                     tags$head(tags$style(HTML("body {background-color: white;color: #F5F5F5; };"))), 
                     tags$head(tags$style(HTML('.skin-blue .sidebar a {color: #ccff00;}')))
                     #tags$head(tags$style(HTML(".well {height: 620px;background-color: #F5F5F5}")))
        ),
        mainPanel(
          shinycssloaders::withSpinner(plotlyOutput((ns("plot_1")))),
          textOutput((ns("out"))),
          htmlOutput(ns("warnmsg")),
          fluidRow(column(3,downloadButton(ns('dataDownload'),"Download selected metrics",
                                           style="color: #fff; background-color: green; border-color: Black;margin-top:
                                                             350px; margin-right: 290px; float:right")))
        )
      )
    )
}
