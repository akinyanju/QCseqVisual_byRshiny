module2_sidebar_UI <- function(id) {
  ns <- NS(id)
  shinydashboard::sidebarMenu(
    fluidRow(column(12,
                    shinyjs::useShinyjs(),
                    shinydashboard::menuItem(selectInput(inputId = ns("app"),
                                                         "Select Application:",
                                                         choices = c("atacseq","basic","chic","chipseq","ctp","pdxrnaseq","pdxrnaseqR2","pdxwgs","rnaseq","rnaseqR2","rrbs","wes","wgs","wgbs"),
                                                         selected = "rnaseq"),
                                             choicesOpt = list(style = rep(("color: black; background: white"),500))),
                    shinydashboard::menuItem(radioButtons(inputId = ns("opt"),"Delivered project",
                                                          choices = c('Yes','No','both'),
                                                          selected = "Yes",inline = T)),
                    shinydashboard::menuItem(pickerInput(inputId = ns("var1"),
                                                         label = "Select Lab",
                                                         choices = NULL,selected = NULL,multiple = T,
                                                         options = pickerOptions(actionsBox = TRUE,
                                                                                 title = "Search group",liveSearch = TRUE,
                                                                                 liveSearchPlaceholder="Search keyword",
                                                                                 liveSearchStyle="contains",
                                                                                 selectedTextFormat = 'count > 1',
                                                                                 countSelectedText = "{0} of {1} labs selected"),
                                                         choicesOpt = list(style = rep(("color: black; background: white"),500)))),
                    shinydashboard::menuItem(div(id=ns("var2_parent"),
                                                 pickerInput(inputId = ns("var2"),
                                                             label = "Project ID: for 'NULL' use only",
                                                             choices = NULL,selected = NULL,multiple = T,
                                                             options = pickerOptions(actionsBox = TRUE,
                                                                                     title = "Search id type",liveSearch = TRUE,
                                                                                     liveSearchPlaceholder="Search keyword",
                                                                                     liveSearchStyle="contains",
                                                                                     selectedTextFormat = 'count > 1',
                                                                                     countSelectedText = "{0} of {1}  id selected"),
                                                             choicesOpt = list(style = rep(("color: black; background: white"),500))))),
                    shinydashboard::menuItem(pickerInput(inputId = ns("var3"),
                                                         label = "Select Project Run",
                                                         choices = NULL,selected = NULL,multiple = T,
                                                         options = pickerOptions(actionsBox = TRUE,
                                                                                 title = "Search project run",liveSearch = TRUE,
                                                                                 liveSearchPlaceholder="Search keyword",
                                                                                 liveSearchStyle="contains",
                                                                                 selectedTextFormat = 'count > 1',
                                                                                 countSelectedText = "{0} of {1}  runs selected"),
                                                         choicesOpt = list(style = rep(("color: black; background: white"),500)))),
                    shinydashboard::menuItem(pickerInput(inputId = ns("var4"),
                                                         label = "Select Flowcell",
                                                         choices = NULL,selected = NULL,multiple = T,
                                                         options = pickerOptions(actionsBox = TRUE,
                                                                                 title = "Search Species",liveSearch = TRUE,
                                                                                 liveSearchPlaceholder="Search keyword",
                                                                                 liveSearchStyle="contains",
                                                                                 selectedTextFormat = 'count > 1',
                                                                                 countSelectedText = "{0} of {1} flowcell selected"),
                                                         choicesOpt = list(style = rep(("color: black; background: black; font-weight: bold;"),0)))),
                    shinydashboard::menuItem(pickerInput(inputId = ns("var5"),
                                                         label = "Select Metric(s)",
                                                         choices = NULL,selected = NULL,multiple = T,
                                                         options = pickerOptions(actionsBox = TRUE,
                                                                                 title = "Search metrics",liveSearch = TRUE,
                                                                                 liveSearchPlaceholder="Search keyword",
                                                                                 liveSearchStyle="contains",
                                                                                 selectedTextFormat = 'count > 1',
                                                                                 countSelectedText = "{0} of {1} metrics selected"),
                                                         choicesOpt = list(style = rep(("color: black; background: white"),500)))),
                    shinydashboard::menuItem(pickerInput(inputId = ns("var6"),
                                                         label = "Select Species",
                                                         choices = NULL,selected = NULL,multiple = T,
                                                         options = pickerOptions(actionsBox = TRUE,
                                                                                 title = "Search Species",liveSearch = TRUE,
                                                                                 liveSearchPlaceholder="Search keyword",
                                                                                 liveSearchStyle="contains",
                                                                                 selectedTextFormat = 'count > 1',
                                                                                 countSelectedText = "{0} of {1} species selected"),
                                                         choicesOpt = list(style = rep(("color: black; background: black; font-weight: bold;"),0)))),
                    shinydashboard::menuItem(radioButtons(ns("plt"),"Plot type",
                                                          choices = c("Vio",'Bar', 'Flo'),
                                                          selected = NULL, inline = T)),
                    h5(tags$b("Application sample size in database:"),
                       withSpinner(textOutput(outputId = ns("App_sample_counter"), inline = FALSE, 
                                              container = tags$h4))),
                    #control the distance between item panels in sidebar
                    tags$head(tags$style(HTML("body {background-color: white;color: black; }"))),
                    tags$head(tags$style(HTML(".form-group {margin-bottom: -5px !important;margin-top: -5px !important;"))),
                    tags$style(HTML('.sidebar-menu li a { font-size: 15px; }')), #Control the sidebar menu font size
                    tags$head(tags$style(HTML(' .skin-blue .sidebar a { color: white; background-color: #CD8162;}' ))),
                    tags$footer(strong("Managed by: GTdrylab team"),
                                align = "left",
                                style = "position:fixed;
                                bottom:0;
                                width:10%;
                                height:30px;
                                font-size: 16px;
                                color: white;
                                padding: 0px;
                                background-color: ;
                                z-index: 100;")
                    )))
  # tags$head(tags$style(".sidebar-menu li { margin-bottom: 0px; margin-left: -15px; }")),
  # fluidRow(style = "margin-top: 10px; margin-left: 5px",
  #         h5(tags$b("Application sample size in database:"),
  #            withSpinner(textOutput(ns("App_sample_counter"), inline = FALSE)))),
  # tags$head(tags$style("#App_sample_counter{color: orange;
  #                                 font-size: 18px;
  #                                  font-style: italic;
  #                                                       }")
  # ),
  # tags$footer(strong("Managed by: GTdrylab team"),
  #            align = "left",
  #            style = "position:fixed;
  #            bottom:0;
  #            width:10%;
  #            height:30px;
  #            font-size: 16px;
  #            color: white;
  #            padding: 0px;
  #            background-color: ;
  #            z-index: 100;"))
}

