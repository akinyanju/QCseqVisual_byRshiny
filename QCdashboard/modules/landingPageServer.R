module1_Server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      
      ###########################################################Read input update
      InputSeqMet <- reactive({
        paste0(seqInputMetdata)
      }) 
      
      InputSeqMet_func <- reactiveValues() # Function used for livestream data. Hold empty arg
      observe({
        if(file.exists(InputSeqMet()) == TRUE) {
          InputSeqMetReaderUpdate  <-  reactiveFileReader(intervalMillis = 500, 
                                                          session = NULL, 
                                                          filePath = InputSeqMet(), 
                                                          readFunc = read.csv) 
        }  else { 
          message("Connection to input file will be established after authentication")
        }
        InputSeqMet_func$appdata <- reactive({
          req(InputSeqMetReaderUpdate()) 
          InputSeqMetReaderUpdate()
        })   
      })
      
      InputSeqMet_gui <- reactive({
        data <- InputSeqMet_func$appdata()
        data$Month <- factor(month.name[data$Month], levels = month.name)
        data <- data |> arrange(Month)
        #quarterly column
        data$quarterly <- ifelse((data$Month=="January" | data$Month=="February" | data$Month=="March"), paste0("Q1"),
                                 ifelse((data$Month=="April" | data$Month=="May" | data$Month=="June"), paste0("Q2"),
                                        ifelse((data$Month=="July" | data$Month=="August" | data$Month=="September"), paste0("Q3"),
                                               ifelse((data$Month=="October" | data$Month=="November" | data$Month=="December"), paste0("Q4"), 
                                                      paste0("unassigned")))))
        # monthly column
        data$monthly <- ifelse((data$Month=="January"), paste0("Q1_01"),
                               ifelse((data$Month=="February"), paste0("Q1_02"),
                                      ifelse((data$Month=="March"), paste0("Q1_03"),
                                             ifelse((data$Month=="April"), paste0("Q2_04"),
                                                    ifelse((data$Month=="May"), paste0("Q2_05"),
                                                           ifelse((data$Month=="June"), paste0("Q2_06"),
                                                                  ifelse((data$Month=="July"), paste0("Q3_07"),
                                                                         ifelse((data$Month=="August"), paste0("Q3_08"),
                                                                                ifelse((data$Month=="September"), paste0("Q3_09"),
                                                                                       ifelse((data$Month=="October"), paste0("Q4_10"),
                                                                                              ifelse((data$Month=="November"), paste0("Q4_11"),
                                                                                                     ifelse((data$Month=="December"), paste0("Q4_12"),
                                                                                                            paste0("unassigned")))))))))))))
        # quarterly with year column
        data$yearly_quarterly <- ifelse((data$Month=="January" | data$Month=="February" | data$Month=="March"), paste0(data$Year, "_Q1"),
                                        ifelse((data$Month=="April" | data$Month=="May" | data$Month=="June"), paste0(data$Year, "_Q2"),
                                               ifelse((data$Month=="July" | data$Month=="August" | data$Month=="September"), paste0(data$Year, "_Q3"),
                                                      ifelse((data$Month=="October" | data$Month=="November" | data$Month=="December"), paste0(data$Year, "_Q4"), 
                                                             paste0(data$Year, "_unassigned")))))
        
        #monthly with year column
        data$yearly_monthly <- ifelse((data$Month=="January"), paste0(data$Year, "_Jan"),
                                      ifelse((data$Month=="February"), paste0(data$Year, "_Feb"), 
                                             ifelse((data$Month=="March"), paste0(data$Year, "_Mar"), 
                                                    ifelse((data$Month=="April"), paste0(data$Year, "_Apr"), 
                                                           ifelse((data$Month=="May"), paste0(data$Year, "_May"), 
                                                                  ifelse((data$Month=="June"), paste0(data$Year, "_Jun"), 
                                                                         ifelse((data$Month=="July"), paste0(data$Year, "_Jul"), 
                                                                                ifelse((data$Month=="August"), paste0(data$Year, "_Aug"), 
                                                                                       ifelse((data$Month=="September"), paste0(data$Year, "_Sep"), 
                                                                                              ifelse((data$Month=="October"), paste0(data$Year, "_Oct"), 
                                                                                                     ifelse((data$Month=="November"), paste0(data$Year, "_Nov"), 
                                                                                                            ifelse((data$Month=="December"), paste0(data$Year, "_Dec"),
                                                                                                                   paste0(data$Year, "_unassigned")))))))))))))
        
        req(input$option)
        if (input$option %in% 'Yes') {
          data$Epoch <- data$monthly
          data$year_epoch <- data$yearly_monthly
        } else if (input$option %in% 'No') {
          data$Epoch <- data$quarterly
          data$year_epoch <- data$yearly_quarterly
        }
        #convert data to long
        data_long <- data %>% tidyr::pivot_longer(cols=Reads:Bytes)
        #sometime, input file is inconsistent with platform names. e.g. two enteries as PacBio and PACBIO
        data_long$Platform <- toupper(data_long$Platform)
        data_long$Application <- toupper(data_long$Application)
        #call data
        data_long 
      }) #%>% bindCache(data_long) 
      
      reac_year_gui <- reactive({
        InputSeqMet_gui() %>% filter(Year %in% input$year)
      }) 
      
      reac_epoch_gui <- reactive({
        reac_year_gui() %>% filter(Epoch %in% input$epoch)
      })
      reac_platform_gui <- reactive({
        reac_epoch_gui() %>% filter(Platform %in% input$platform)
      })
      reac_application_gui <- reactive({
        reac_platform_gui() %>% filter(Application %in% input$application)
      })
      reac_metrics_gui <- reactive({
        reac_application_gui() %>% filter(name %in% input$metrics)
      })
      #########
      observeEvent(input$option, {
        updatePickerInput(session = session, inputId = "year",
                          choices = sort(unique(as.character(InputSeqMet_gui()$Year)), decreasing = TRUE),
                          selected = sort(unique(as.character(InputSeqMet_gui()$Year)), decreasing = TRUE)[1:2])
      })
      observeEvent(input$option, {
        updatePickerInput(session = session, inputId = "epoch",
                          choices = sort(unique(as.character(InputSeqMet_gui()$Epoch)), decreasing = FALSE),
                          selected = sort(unique(as.character(InputSeqMet_gui()$Epoch)), decreasing = FALSE))
      })
      observeEvent(input$option, {
        updatePickerInput(session = session, inputId = "platform",
                          choices = sort(unique(as.character(InputSeqMet_gui()$Platform))),
                          selected = sort(unique(as.character(InputSeqMet_gui()$Platform)))[1])
      })
      Appchannel <- reactive({
        list(input$platform,input$epoch,input$year)
      })
      observeEvent(Appchannel(), {
        if (isTRUE(unique(reac_platform_gui()[reac_platform_gui()$Platform == 'ILLUMINA',]
                          $Platform == 'ILLUMINA'))) {
          updatePickerInput(session = session, inputId = "application",
                            choices = sort(unique(as.character(reac_platform_gui()$Application))),
                            selected = sort(unique(as.character(reac_platform_gui()$Application))))
          shinyjs::enable("application_parent")
          shinyjs::enable("application")
          shinyjs::show("application")
          req(input$more_plots_opt)
        } else {
          updatePickerInput(session = session, inputId = "application",
                            choices = sort(unique(as.character(reac_platform_gui()$Application))),
                            selected = sort(unique(as.character(reac_platform_gui()$Application))))
          shinyjs::disable("application_parent")
          shinyjs::hide("application")
          shinyjs::disable("application")
        }
      })
      observeEvent(input$application, {
        updatePickerInput(session = session, inputId = "metrics",
                          choices = sort(unique(as.character(reac_application_gui()$name))),
                          selected = sort(unique(as.character(reac_application_gui()$name)))[1])
      })
      
      ##############Additional plots
      channel <- reactive({
        list(input$more_plot,input$more_plots_opt, input$platform,input$epoch,input$year, input$application)
      })
      observeEvent(channel(), {
        req(input$more_plot)
        req(input$more_plots_opt)
        req(input$site)
        if ((input$more_plot %in% 'Yes')) {
          shinyjs::disable(id="site")
          shinyjs::enable(id="more_plots_opt")
          shinyjs::show(id="more_plots_opt")
          if (input$more_plots_opt %in% 'Machine') {
            updatePickerInput(session = session, inputId = "instrument",
                              choices = sort(unique(as.character(reac_application_gui()$InstrumentID))),
                              selected = sort(unique(as.character(reac_application_gui()$InstrumentID))))
            shinyjs::disable("instrument_parent")
            shinyjs::hide("instrument")
            shinyjs::disable("instrument")
            shinyjs::disable("lab_parent")
            shinyjs::hide("lab")
            shinyjs::disable("lab")
            shinyjs::show("metrics")
            if (isTRUE(unique(reac_platform_gui()[reac_platform_gui()$Platform == 'ILLUMINA',]
                              $Platform == 'ILLUMINA'))) {
              shinyjs::enable("application_parent")
              shinyjs::enable("application")
              shinyjs::show("application")
            } 
          } else if (input$more_plots_opt %in% 'Lab') {
             updatePickerInput(session = session, inputId = "lab",
                               choices = sort(unique(as.character(reac_application_gui()$groupFolder))),
                               selected = sort(unique(as.character(reac_application_gui()$groupFolder))))
             shinyjs::enable("lab_parent")
             shinyjs::show("lab")
             shinyjs::enable("lab")
             shinyjs::show("metrics")
             if (isTRUE(unique(reac_platform_gui()[reac_platform_gui()$Platform == 'ILLUMINA',]
                               $Platform == 'ILLUMINA'))) {
               shinyjs::enable("application_parent")
               shinyjs::enable("application")
               shinyjs::show("application")
             } 
          } else if (input$more_plots_opt %in% 'Project') {
            shinyjs::hide("application")
            shinyjs::hide("metrics")
            shinyjs::disable("lab_parent")
            shinyjs::hide("lab")
            shinyjs::disable("lab")
            updatePickerInput(session = session, inputId = "application",
                              choices = sort(unique(as.character(reac_platform_gui()$Application))),
                              selected = sort(unique(as.character(reac_platform_gui()$Application))))
          } 
        } else if ((input$more_plot %in% 'No')) {
          if (isTRUE(unique(reac_platform_gui()[reac_platform_gui()$Platform == 'ILLUMINA',]
                            $Platform == 'ILLUMINA'))) {
            shinyjs::enable("application_parent")
            shinyjs::enable("application")
            shinyjs::show("application")
          } 
          shinyjs::show("metrics")
          shinyjs::enable(id="site")
          shinyjs::disable(id="more_plots_opt")
          shinyjs::hide("more_plots_opt")
          shinyjs::disable("instrument_parent")
          shinyjs::hide("instrument")
          shinyjs::disable("instrument")
          shinyjs::disable("lab_parent")
          shinyjs::hide("lab")
          shinyjs::disable("lab")
        }
      })

      
      ######################################################################################
      #This part needs to be filtered separately to ensure that only the filtered data can be downloaded should there be a need to retrieve the selected data.
      react_input_Main <- reactive(
        if (isTRUE(unique(reac_platform_gui()[reac_platform_gui()$Platform == 'ILLUMINA',]
                          $Platform == 'ILLUMINA'))) {
          filter(reac_application_gui(), 
                 Year %in% input$year,
                 Epoch %in% input$epoch,
                 Platform %in% input$platform,
                 Application %in% input$application,
                 name %in% input$metrics)
        } else {
          filter(reac_application_gui(), 
                 Year %in% input$year,
                 Epoch %in% input$epoch,
                 Platform %in% input$platform,
                 name %in% input$metrics
          )
        }) 
      # 
      react_input <- reactive({
        if (input$more_plot == 'Yes' && input$more_plots_opt == 'Machine') {
          filter(react_input_Main(), 
                 Year %in% input$year,
                 Epoch %in% input$epoch,
                 Platform %in% input$platform,
                 Application %in% input$application,
                 name %in% input$metrics,
                 InstrumentID %in% input$instrument
          )
        } else if (input$more_plot == 'Yes' && input$more_plots_opt == 'Lab') {
          filter(react_input_Main(),
                 Year %in% input$year,
                 Epoch %in% input$epoch,
                 Platform %in% input$platform,
                 Application %in% input$application,
                 name %in% input$metrics,
                 groupFolder %in% input$lab
          )
        } else if (input$more_plot == 'Yes' && input$more_plots_opt == 'Project') {
          filter(react_input_Main(),
                 Year %in% input$year,
                 Epoch %in% input$epoch,
                 Platform %in% input$platform,
                 Application %in% input$application,
                 name %in% input$metrics
          )
        } else {
          react_input_Main()
        }
      })
      #Define the summary for each plot
      react_input_grp <- reactive({
        data <- react_input() #define reactive in a regular object
        data$value <- as.numeric(gsub(',','',data$value)) 
        data <- data  |>
          group_by(Platform, year_epoch, Application, Site, groupFolder, InstrumentID, Month)
        data
      })
      ##
      
      #
      react_input_grp_App_Merge <- reactive({
        req(input$site)
        if ((input$option %in% "Yes")) {
            output$warnmsg <- renderUI({
              HTML(paste("Make selection or wait for your selection to be plotted", sep="<br/>"))
            })
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch,
                                                                               Application=react_input_grp()$Application, Year=react_input_grp()$Year, 
                                                                               Month=react_input_grp()$Month), sum) |>
            arrange(Month) %>%  arrange(Year) |>  ungroup()
          data
        } else {
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch,
                                                                               Application=react_input_grp()$Application, Year=react_input_grp()$Year), sum) |>
            arrange(Year) |>  ungroup()
          data
        }
      })
      #
      react_input_grp_App_Split <- reactive({
        req(input$site)
        if ((input$option %in% "Yes")) {
          output$warnmsg <- renderUI({
            HTML(paste("Make selection or wait for your selection to be plotted", sep="<br/>"))
          })
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch, Site=react_input_grp()$Site,
                                                                               Application=react_input_grp()$Application, Year=react_input_grp()$Year, 
                                                                               Month=react_input_grp()$Month), sum) |>
            arrange(Month) %>%  arrange(Year) |>  ungroup()
          data
        } else {
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch, Site=react_input_grp()$Site,
                                                                               Application=react_input_grp()$Application, Year=react_input_grp()$Year), sum) |>
            arrange(Year) |>  ungroup()
          data
        }
      })
      #
      react_input_grp_Instrument <- reactive({
        req(input$site)
        if ((input$option %in% "Yes")) {
          output$warnmsg <- renderUI({
            HTML(paste("Make selection or wait for your selection to be plotted", sep="<br/>"))
          })
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch, 
                                                                               InstrumentID=react_input_grp()$InstrumentID, Year=react_input_grp()$Year, 
                                                                               Month=react_input_grp()$Month), sum) |>
            arrange(Month) %>%  arrange(Year) |>  ungroup()
          data
        } else {
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch, InstrumentID=react_input_grp()$InstrumentID, 
                                                                               Year=react_input_grp()$Year), sum) |>
            arrange(Year) |>  ungroup()
          data
        }
      })
      #
      react_input_grp_lab <- reactive({
        req(input$site)
        if ((input$option %in% "Yes")) {
          output$warnmsg <- renderUI({
            HTML(paste("Make selection or wait for your selection to be plotted", sep="<br/>"))
          })
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch, 
                                                                               groupFolder=react_input_grp()$groupFolder, Year=react_input_grp()$Year, 
                                                                               Month=react_input_grp()$Month), sum) |>
            arrange(Month) %>%  arrange(Year) |>  ungroup()
          data
        } else {
          data <- aggregate(list(value_sum=react_input_grp()$value), by = list(year_epoch=react_input_grp()$year_epoch, 
                                                                               groupFolder=react_input_grp()$groupFolder, 
                                                                               Year=react_input_grp()$Year), sum) |>
            arrange(Year) |>  ungroup()
          data
        }
      })
      #
      react_input_grp_count <- reactive({
        data <- react_input()
        data <- data  |> group_by(Application, year_epoch, Month, Year)  |> summarize(AppCounts=length((Application)))
        if ((input$option %in% "Yes")) {
          output$warnmsg <- renderUI({
            HTML(paste("Make selection or wait for your selection to be plotted", sep="<br/>"))
          })
          data <- aggregate(list(AppCount=data$AppCounts), by = list(year_epoch=data$year_epoch,Application=data$Application,
                                                                     Year=data$Year, 
                                                                     Month=data$Month), sum) |>
            arrange(Month) %>%  arrange(Year) |>  ungroup()
          data
        } else {
          data <- aggregate(list(AppCount=data$AppCounts), by = list(year_epoch=data$year_epoch,Application=data$Application,
                                                                     Year=data$Year), sum) |>
            arrange(Year) |>  ungroup()
          data
        }
      })
      
      #Source the plotting function
      source("/srv/shiny-server/plot/landingPagePlotCode.R", local = TRUE)
      #source("/Users/lawalr/Dropbox/My-script/AssociateCompSci/RshinyModules/plot/landingPagePlotCode.R", local=TRUE)
      
      #InputSeqMet_gui()
      react_input_long <- reactive({
        data_wide <- react_input() |> 
          pivot_wider(names_from = name, values_from = value, values_fn = list) |> 
          unnest(cols = everything())
      })
      
      downloadfunc <- reactive({
        dropColumns <- c("quarterly","monthly","yearly_quarterly","yearly_monthly","Epoch","year_epoch")
        react_input_long()[,!(names(react_input_long()) %in% dropColumns)]
      })

      output$dataDownload <- downloadHandler(
        filename = function(){"gtQuarterlyMetrics.csv"}, 
        content = function(fname){
          write.csv(downloadfunc(), fname, row.names = FALSE)
        }
      ) 
    }
  )
}
