output$plot_type<-renderUI({
  radioButtons("plt","Plot type",choices = c("Vio", 
                                             'Bar', 'Flo'),
               selected = NULL, inline = T)
})

output$plot = renderPlotly({
  if (length(unique(react_input_long()$Investigator_Folder)) <= 25 ) {
    axis_text_size <- 13
  } 
  if (length(unique(react_input_long()$Project_run_type)) <= 4 ) {
    face_wrap_strip_size <- 15
  } else {
    axis_text_size <- 10
    face_wrap_strip_size <- 10
  }
  geom_theme <- function(){
    theme(legend.title=element_text(size=15), 
          legend.text=element_text(size=15)) +
      theme(axis.title.x = element_text(size=15, color="black")) + 
      theme(axis.title.y = element_text(size=15, color="black")) + 
      theme(axis.text = element_text(size=axis_text_size, color="black")) +
      theme(legend.position="none") #theme(legend.position="bottom")
  }
  #Set variable for legend
  
  if ((input$plt %in% "Vio")) {
    if(any(grepl("PCT", react_input_long()$name)) != all(grepl("PCT", react_input_long()$name))) {
      output$warnmsg <- renderUI({
        HTML(paste("Error: Plotting prevented because:", "1)  You mixed 'PCT' in your selection of metrics or", 
                   "2)  One or more item(s) is not selected", sep="<br/>"))
      })
      return()
    } else if (any(grepl("PCT", react_input_long()$name))){
      output$warnmsg <- renderUI({})
      legend <- "Percentage (%)"
    } else {
      output$warnmsg <- renderUI({})
      legend <- "Read"
    }#
    react_input_vio_long <- reactive({
      sample_size = react_input_long() %>% group_by(Investigator_Folder) %>% summarize(num=sort(length(unique(Sample_Name))))
      tmp <- react_input_long() %>%
        left_join(sample_size) %>%
        mutate(myaxis = paste0(Investigator_Folder, " (", "n=", num, ")")) 
      tmp %>% 
        mutate(tickvals = paste0(as.numeric(as.data.frame(unclass(tmp),stringsAsFactors=TRUE)$myaxis))) %>% 
        mutate(ticktext = paste0(as.data.frame(unclass(tmp),stringsAsFactors=F)$myaxis))
    })
    as.data.frame(unclass(react_input_vio_long()),stringsAsFactors=TRUE) %>%
      plot_ly(width = 1200, height = 700) %>% 
      add_trace(x = ~as.numeric(myaxis),y = ~value, color = ~name, split = ~name,
                type = 'violin',box = list(visible = T),meanline = list(visible = T), 
                hoverinfo = 'name+y') %>%
      add_markers(x = ~jitter(as.numeric(myaxis)), y = ~value, color = ~name, split = ~name,
                  marker = list(size = 6),
                  hoverinfo = "text", 
                  text = ~paste0(
                    "<br>metric value: ",value,
                    "<br>metric name: ",name,
                    "<br>lab: ",Investigator_Folder,
                    "<br>flowcellid: ",FlowcellID,
                    "<br>run: ",Project_run_type,
                    "<br>Sample: ",Sample_Name), 
                  showlegend = FALSE) %>%
      layout(legend = list(orientation = "h",
                           x =0.5, xanchor = "center",
                           y = 1, yanchor = "bottom"
      ), xaxis = list(title = "",
                      showticklabels = TRUE, tickangle = 300,
                      tickmode = "array", 
                      tickvals = ~tickvals, 
                      ticktext = ~ticktext, tickfont = list(size = 10)), 
      yaxis = list(title = legend, zeroline = T),
      violinmode = 'group', showlegend = T, autosize = F)
    
  }
  else if(input$plt %in% "Flo"){
    if(any(grepl("PCT", react_input()$name)) != all(grepl("PCT", react_input()$name))) {
      output$warnmsg <- renderUI({
        HTML(paste("Error: Plotting prevented because:", "1)  You mixed 'PCT' in your selection of metrics or", 
                   "2)  One or more item(s) is not selected", sep="<br/>"))
      })
      return()
    } else if (any(grepl("PCT", react_input()$name))){
      output$warnmsg <- renderUI({})
      legend <- "Percentage (%)"
    } else {
      output$warnmsg <- renderUI({})
      legend <- "Read"
    }
    #For compare plot, if user select two metrics for y-axis, only display the first.
    react_input_corr <- reactive({
      react_input() %>% filter(name %in% input$var5[1])
    })
    output$home  <- renderText({
      str(react_input_corr()$name)
    })
    ylabel <- unique(react_input_corr()$name)
    sample_size = react_input_corr() %>% group_by(Investigator_Folder) %>% summarize(num=sort(length(unique(Sample_Name))))
    p <- react_input_corr() %>%
      left_join(sample_size) %>%
      mutate(label = paste0(Project_run_type, "/", FlowcellID, "/", "Sample, n=", num)) %>%
      ggplot(aes(x = Lane, y = value, group = name), 
             add = "reg.line", palette = "jco") +
      geom_line() + geom_point() + ylab(ylabel) +
      #stat_cor(method = "pearson",  size = 6, label.x.npc = 0.3, color="blue") +
      geom_theme() + theme(legend.position="none") + theme(strip.text = element_text(size = face_wrap_strip_size)) +
      facet_wrap(~label, ncol=2) #+ labs(title=title$label)
    ggplotly(p, width = (0.80*as.numeric(input$dimension[1])), height = (0.80*as.numeric(input$dimension[2])))
    #geom_errorbar(aes(ymin=yvalue - paste0(input$yaxis, "_SD"), ymax=yvalue + paste0(input$yaxis, "_SD")), colour="black", width=0.1)
    #geom_smooth(method = "lm", color = "black", se = TRUE)
  }
  #cor_plot <- function(dataframe,  xvalue, yvalue, fillvalue) {
  #geom_errorbar(aes(ymin=(Mean-StErr), ymax=(Mean+StErr)), colour="black", width=0.1)+
  #ggplot(dataframe, aes(x = {{xvalue}}, y = {{yvalue}}, fill = {{fillvalue}})
  #cor_plot(react_input(), Lane, value, name) 
  else {
    if(any(grepl("PCT", react_input_long()$name)) != all(grepl("PCT", react_input_long()$name))) {
      output$warnmsg <- renderUI({
        HTML(paste("Error: Plotting prevented because:", "1)  You mixed 'PCT' in your selection of metrics or", 
                   "2)  One or more item(s) is not selected", sep="<br/>"))
      })
      return()
    } else if (any(grepl("PCT", react_input_long()$name))){
      
      # sample_size = react_input_long() %>% group_by(Investigator_Folder) %>% 
      #   summarize(num=sort(length(unique(Sample_Name))))
      # 
      # react_value <- reactive({
      #   react_input_long() %>% group_by(Investigator_Folder, name) %>% 
      #     summarise(across(value, list(mean = mean, sum = sum)))
      # })
      #
      output$warnmsg <- renderUI({})
      legend <- "Percentage (% 'mean')"
      #
      react_value() %>%
        left_join(sample_size()) %>%
        mutate(myaxis = paste0(Investigator_Folder, " (", "n=", num, ")")) %>% 
        plot_ly(x = ~myaxis, y = ~value_mean, split = ~name, width = 1200, height = 700,
                type = 'bar') %>%
        layout(yaxis = list(title = legend, zeroline = T), showlegend = T, 
               legend = list(orientation = "h",
                             x =0.5, xanchor = "center",
                             y = 1, yanchor = "bottom"),
               xaxis = list(title = "", tickangle = 300, showticklabels = TRUE, tickfont = list(size = 12)),
               barmode = 'group', autosize = F)
    } else {
      output$warnmsg <- renderUI({})
      legend <- "Total sum of reads"
      #
      react_value() %>%
        left_join(sample_size()) %>%
        mutate(myaxis = paste0(Investigator_Folder, " (", "n=", num, ")")) %>% 
        plot_ly(x = ~myaxis, y = ~value_sum, split = ~name, width = 1200, height = 700,
                type = 'bar') %>%
        layout(yaxis = list(title = legend, zeroline = T), showlegend = T, 
               legend = list(orientation = "h",
                             x =0.5, xanchor = "center",
                             y = 1, yanchor = "bottom"),
               xaxis = list(title = "", tickangle = 300, showticklabels = TRUE, tickfont = list(size = 12)),
               barmode = 'group', autosize = F)
    }
  }
})
