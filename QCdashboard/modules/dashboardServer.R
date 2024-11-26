module2_Server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ###########################################################Functions updating input qc file in real time
    # Reactive File-reader based on user selectInput
    InputFilePath <- reactive({
      paste0(dir_InputFile,"/",input$app,input_suffix)
    }) 
    
    InputData_func <- reactiveValues() # Function used for livestream data. Hold empty arg
    observe({
      if(file.exists(InputFilePath()) == TRUE) {
        InputFileReaderUpdate  <-  reactiveFileReader(intervalMillis = 500, 
                                                      session = NULL, 
                                                      filePath = InputFilePath(), 
                                                      readFunc = InputFileReader) 
      }  else { 
        message("Connection to input file will be established after authentication")
      }
      InputData_func$appdata <- reactive({
        req(InputFileReaderUpdate()) 
        #message("Testing cache 1...")
        #Sys.sleep(1)
        InputFileReaderUpdate()
      }) #%>% bindCache(InputFileReaderUpdate()) %>% bindEvent(input$app) 
    })  
    ###########################################################Wrap updated input file in new variable
    App_gui <- reactive({
      #message("Testing cache 2...")
      #Sys.sleep(1)
      InputData_func$appdata()}) #%>% bindCache(InputData_func$appdata()) %>% bindEvent(input$app) 
    ###########################################################React with Delivery Project
     reac_App_gui <- reactive({
      #get(input$app)
      req(input$opt)
      if ((input$opt %in% 'Yes')) {
        #App_gui()[!grepl('NULL', App_gui()$Investigator_Folder),]
        App_gui()[with(App_gui(), !grepl("NULL", paste(Investigator_Folder, Release_Date))),]
      } else if ((input$opt %in% 'No')) {
        #App_gui()[grepl('NULL', App_gui()$Investigator_Folder),]
        App_gui()[with(App_gui(), grepl("NULL", paste(Investigator_Folder, Release_Date))),]
      } else if ((input$opt %in% 'both')) {
        App_gui()
      }
    })
    
    ###########################################################Reactive with sidebar menu
    #functions below filter on each other, based on prior selection.
    reac_Investigator_gui <- reactive({
      reac_App_gui() %>% filter(Investigator_Folder %in% input$var1)
    })
    reac_ProjectID_gui <- reactive({
      reac_Investigator_gui() %>% filter(Project_ID %in% input$var2)
    })
    reac_ProjRun_gui <- reactive({
      reac_Investigator_gui() %>% filter(Project_run_type %in% input$var3)
    })
    reac_Flowcell_gui <- reactive({
      reac_ProjRun_gui() %>% filter(FlowcellID %in% input$var4)
    })
    ###########################################################
    #This section react instantly to user filter in the sidebar menu. Its funtions are to regular
    #observe user interraction in the sidebar menu and then update the selection according to filter
    
    #The input$app observeEvent object react to application select input instantly on the Investigator_Folder
    observeEvent(input$app, {
      updatePickerInput(session = session, inputId = "var1",
                        choices = sort(unique(as.character(reac_App_gui()$Investigator_Folder))),
                        selected = sort(unique(as.character(reac_App_gui()$Investigator_Folder)))[1])
    })
    #The input$opt observeEvent object react to application select input instantly on the Investigator_Folder but
    #based on the radiobutton selection
    observeEvent(input$opt, {
      updatePickerInput(session = session, inputId = "var1",
                        choices = sort(unique(as.character(reac_App_gui()$Investigator_Folder))),
                        selected = sort(unique(as.character(reac_App_gui()$Investigator_Folder)))[1])
    })
    #####Disable and Enable funtion to ensure that Project ID is activated only for NULL groups
    #This is because, the only known identifier for NULL projects is under the column for Project ID...
    #thus, enabling user distinguish which of the lab the NULL is coming from. 
    observeEvent(input$var1, {
      if (isTRUE(unique(reac_Investigator_gui()[reac_Investigator_gui()$Investigator_Folder == 'NULL',]
                        $Investigator_Folder == 'NULL'))) {
        updatePickerInput(session = session, inputId = "var2",
                          choices = sort(unique(as.character(reac_Investigator_gui()$Project_ID))),
                          selected = sort(unique(as.character(reac_Investigator_gui()$Project_ID)))[1])
        shinyjs::enable("var2_parent")
        shinyjs::enable("var2")
        shinyjs::show("var2")
      } else {
        updatePickerInput(session = session, inputId = "var2",
                          choices = sort(unique(as.character(reac_Investigator_gui()$Project_ID))),
                          selected = NULL)
        shinyjs::disable("var2_parent")
        shinyjs::hide("var2")
        shinyjs::disable("var2")
      }
    })
    #
    observeEvent(input$var2, {
      if (isTRUE(unique(reac_Investigator_gui()[reac_Investigator_gui()$Investigator_Folder == 'NULL',]
                        $Investigator_Folder == 'NULL'))) {
        updatePickerInput(session = session, inputId = "var3",
                          choices = sort(unique(as.character(reac_ProjectID_gui()$Project_run_type))),
                          selected = sort(unique(as.character(reac_ProjectID_gui()$Project_run_type)))[1])
      }
    })
    observeEvent(input$var1, {
      if (!isTRUE(unique(reac_Investigator_gui()[reac_Investigator_gui()$Investigator_Folder == 'NULL',]
                         $Investigator_Folder == 'NULL'))) {
        updatePickerInput(session = session, inputId = "var3",
                          choices = sort(unique(as.character(reac_Investigator_gui()$Project_run_type))),
                          selected = sort(unique(as.character(reac_Investigator_gui()$Project_run_type)))[1])
      }
    })
    #
    observeEvent(input$var3, {
      updatePickerInput(session = session, inputId = "var4",
                        choices = sort(unique(as.character(reac_ProjRun_gui()$FlowcellID))),
                        selected = sort(unique(as.character(reac_ProjRun_gui()$FlowcellID)))[1])
    })
    
    #
    observeEvent(input$var4, {
      updatePickerInput(session = session, inputId = "var5",
                        choices = ((unique(as.character(reac_Flowcell_gui()$name)))),
                        selected = c("Reads_Total")) #, "Reads_Filtered"
    })
    observeEvent(input$var4, {
      updatePickerInput(session = session, inputId = "var6",
                        choices = sort(unique(as.character(reac_Flowcell_gui()$Species))),
                        selected = sort(unique(as.character(reac_Flowcell_gui()$Species))))
    })
    ###########################################################
    #Function that takes all user selection (subset data) from global data to a new variable.
    #This new variable is what will pass into plot, downloads and other stats
    react_input <- reactive(
      if (!isTRUE(unique(reac_Investigator_gui()[reac_Investigator_gui()$Investigator_Folder == 'NULL',]
                         $Investigator_Folder == 'NULL'))) {
        filter(reac_App_gui(), 
               Investigator_Folder %in% input$var1,
               Project_run_type %in% input$var3,
               FlowcellID %in% input$var4,
               name %in% input$var5,
               Species %in% input$var6)
      } else {
        filter(reac_App_gui(), 
               Investigator_Folder %in% input$var1,
               Project_ID %in% input$var2,
               Project_run_type %in% input$var3,
               FlowcellID %in% input$var4,
               name %in% input$var5,
               Species %in% input$var6)
      }) 
    ###########################################################
    #Because a sample can have multiple runs in each flowcell, this duplicate information remains 
    #redundant for certain plot and general stats. We need to remove this duplicate. 
    #Note that react_input() contains all columns for subset of data and used in other part of the server
    react_input_wide_rmdupsample <- reactive({
      data_wide <- react_input() |> 
        pivot_wider(names_from = name, values_from = value, values_fn = list) |> 
        unnest(cols = everything())
      #
      data_wide[!duplicated(data_wide$Sample_Name),]
    })
    ###########################################################
    #We need to reconvert the metrics column from wide to long. To do that, we need the 
    #column position of the first column metrics. In this case, "Reads_Total". 
    #The effective way to do this is to determine the last column before before the first metric 
    #column and then add 1 (see react_input_long() function)
    Col_num <- reactive({
      (which(colnames(react_input_wide_rmdupsample()) == "ProjStatus")) 
    })
    
    #due to reaction, metrics are added based on user input. Therefore, we accommodate for that 
    #reaction by asking col starting from "Reads_Total" to be pivoted to long. This means, default 
    #selected column must be at minimum Reads_Total". When users add metrics that come after 
    #Reads_Total", they will be pivoted to long, one at a time and under a column "name"
    react_input_long <- reactive({
      tryCatch(
        react_input_wide_rmdupsample() %>% tidyr::pivot_longer( 
          cols = all_of(colnames((react_input_wide_rmdupsample())
                                 [c((Col_num()+1):
                                      ncol(react_input_wide_rmdupsample()))]))), 
        error = function(e) return()
      )
    })
    
    sample_size <- reactive({react_input_long() %>% group_by(Investigator_Folder) %>% 
      summarize(num=sort(length(unique(Sample_Name))))
    })
    
    react_value <- reactive({
      react_input_long() %>% group_by(Investigator_Folder, name) %>% 
        summarise(across(value, list(mean = mean, sum = sum)))
    })
    ###########################################################Plotting area
    #Here is where all display code will be added. 
    #Do note that the variable containing all data point is found in reac_data() 
    #define plot command options
    
    source("/srv/shiny-server/plot/DashboardPlotCode.R", local = TRUE)
    #source("/Users/lawalr/Dropbox/My-script/AssociateCompSci/RshinyModules/plot/DashboardPlotCode.R", local = TRUE)
    
    ############################################################function to download data
    #Keep all lane information for each sample, otherwise, just use react_input_wide_rmdupsample() as main input with the downloadFunc
    react_input_wide <- reactive({
      react_input() |> 
        pivot_wider(names_from = name, values_from = value, values_fn = list) |> 
        unnest(cols = everything())
    })
    #
    downloadfunc <- reactive(react_input_wide())
    output$dataDownload <- renderDataTable({downloadfunc()})
    output$download <- downloadHandler(
      filename = function(){"gtQCmetrics.csv"}, 
      content = function(fname){
        write.csv(downloadfunc(), fname, row.names = FALSE)
      }
    ) 
    ############################################################Summary Stats
    output$summary <- renderPrint({
      tryCatch(
        summary((react_input_wide_rmdupsample())[c((Col_num()+1):ncol(react_input_wide_rmdupsample()))]),
        error = function(e) return("Select at least one metric")
      )
    })
    output$describe <- renderPrint({
      tryCatch(
        describeBy((react_input_wide_rmdupsample()[-(1:Col_num())]),
                   group=react_input_wide_rmdupsample()$Investigator_Folder, fast=TRUE),
        error = function(e) return("Select more than one metric to view summary")
      )
    })
    ############################################################Database sample counter
    output$App_sample_counter <- renderText({paste0(length(unique(reac_App_gui()$Sample_Name)), 
                                                    " (of ", total_database_samples, " )" )})
  })
}

