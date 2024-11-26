module2_body_UI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      mainPanel(
        tabsetPanel(type = "tabs", 
                    tabPanel("Overview", verbatimTextOutput(ns("home")),
                             br(),
                             h2(strong(style = "color:cornflowerblue",
                                       "Welcome to JAX GT QC metrics dashboard")),
                             br(),
                             h5(p("This dashboard captures more expanded QC metrics than the standard deliverables. Users will be able
                              to recover all historic metrics archived since the inception of our qifa-qc pipeline in 2018.
                              Importantly, dashboard is updated every 10 minutes which means newly delivered QC can be accessible to
                              users quickly.")),
                             br(),
                             h4(p("While you explore high-quality visualizations of QC metrics, this project is still in a beta ware and
                         we seek your feedback to help improving it. Email gtdrylab@jax.org for questions and feedback.")),
                             br(),
                             h4(em(style = "color:brown","Note to Gatekeepers:")),
                             h4(em(style = "color:cornflowerblue","Known plotting issues to fix:")), 
                             h5(p("1. Points plot become ungrouped when > 1 metrics is selected under 'Vio plot type'")),
                             h5(p("2. Metrics with *_SD naming convention is the corresponding std dev for the metrics. 
                                Future update will use this *_SD value as error bar in the 'Flo plot type'")),
                             h4(em(style = "color:cornflowerblue","Other info:")),
                             h5(p("1. Only Y-axis is changeable in 'Flo plot type' and accept single metric selection. 
                              If you select > 1 metrics, it will default to your first selection. 
                              X-axis is defaulted to Lane. Use this plot type to compare lane performance against metrics selection")),
                             h4(em(style = "color:brown","Please send all comments and regular feedback to gtdrylab@jax.org")),
                             br(),
                             h4(em(style = "color:green","****New update****")),
                             h5(p("[09/27/24]: fixed minor bugs including bar plot")),
                             h5(p("[05/13/24]: 'basic' is now added under 'Application' menu and contains metrics from amplicon and any projects with no specific library type"))
                    ),
                    tabPanel("Plot", shinycssloaders::withSpinner(plotlyOutput(ns("plot"), width = "auto")), htmlOutput(ns("warnmsg")), 
                             tags$head(tags$style("#warnmsg{color: red;font-size: 20px;font-style: italic;}"
                             )),
                             tags$script('var dimension = [0, 0];
                           $(document).on("shiny:connected", function(e) {
                           dimension[0] = window.innerWidth;
                           dimension[1] = window.innerHeight;
                           Shiny.onInputChange("dimension", dimension);
                           });
                           $(window).resize(function(e) {
                           dimension[0] = window.innerWidth;
                           dimension[1] = window.innerHeight;
                           Shiny.onInputChange("dimension", dimension);
                           });
                                          ')
                    ),
                    tabPanel("SummaryByAll", shinycssloaders::withSpinner(verbatimTextOutput(ns("summary")))),
                    tabPanel("SummaryByLab", shinycssloaders::withSpinner(verbatimTextOutput(ns("describe")))),
                    tabPanel("DownloadTable", shinycssloaders::withSpinner(downloadButton(ns('download'),"Download below metrics",
                                                                                          style="color: #fff; background-color:
                                                                                        green; border-color: Black;")),
                             fluidRow(column(1,box(div(style='width:1200px;overflow-x: scroll;'
                                                 ,dataTableOutput(ns('dataDownload'))))))),
                    
        ))
    ))
}

