output$plot_1 = renderPlotly({
  req(input$option)
  if (input$option %in% 'Yes') {
    xlegend <- "Months"
  } else if (input$option %in% 'No') {
    xlegend <- "Quarters"
  }
  
  if (input$metrics == 'Bases') {
    ylegend <- paste0(input$metrics," (Gb)")
  } else {
    ylegend <- paste0(input$metrics," (G)")
  }
  
  req(input$more_plot)
  req(input$more_plots_opt)
  req(input$metrics)
  req(input$platform)
  if (input$more_plot == 'Yes' && input$more_plots_opt == 'Machine') {
    react_input_grp_Instrument() %>%
      plot_ly(x = ~year_epoch, y = ~value_sum/1e9, width = 1200, height = 700,
              type = 'bar', split =~InstrumentID,
              hoverinfo = 'text',
              text = ~paste0('</br> Machine: ', InstrumentID,
                             '</br> Value: ', round(value_sum/1e9, 2)," Gb",
                             '</br> Epoch: ', year_epoch), textposition = "none") %>% 
      layout(yaxis = list(title = ylegend, zeroline = T, tickformat = "digit"), showlegend = T,
             legend = list(orientation = "h",
                           x =0.5, xanchor = "center",
                           y = 1, yanchor = "bottom"),
             xaxis = list(title = xlegend, tickangle = 300, showticklabels = TRUE, tickfont = list(size = 12),
                          categoryorder = "array", categoryarray = ~ reorder(year_epoch, value_sum)),
             barmode = 'stack', autosize = F, title= list(text = paste0(input$platform),x = 0)) 
  } else if (input$more_plot == 'Yes' && input$more_plots_opt == 'Lab') {
    react_input_grp_lab() %>%
      plot_ly(x = ~groupFolder, y = ~value_sum/1e9, width = 1200, height = 700,
              type = 'bar', split =~year_epoch,
              hoverinfo = 'text',
              text = ~paste0('</br> Group: ', groupFolder,
                             '</br> Value: ', round(value_sum/1e9, 2)," Gb",
                             '</br> Epoch: ', year_epoch), textposition = "none") %>% #type = "log",,#paste0("Log [",input$metrics," (Gb)]")
      layout(yaxis = list(title = ylegend, zeroline = T, tickformat = "digit"), showlegend = T,
             legend = list(orientation = "h",
                           x =0.5, xanchor = "center",
                           y = 1, yanchor = "bottom"),
             xaxis = list(title = xlegend, tickangle = 300, showticklabels = TRUE, tickfont = list(size = 12),
                          categoryorder = "array", categoryarray = ~ reorder(year_epoch, value_sum)),
             barmode = 'stack', autosize = F, title= list(text = paste0(input$platform),x = 0))
  } else if (input$more_plot == 'Yes' && input$more_plots_opt == 'Project') {
    react_input_grp_count() %>%
      plot_ly(x = ~year_epoch, y = ~AppCount, width = 1200, height = 700,
              type = 'bar', split =~Application,
              hoverinfo = 'text',
              text = ~paste0('</br> App: ', Application,
                             '</br> Value: ', AppCount,
                             '</br> Epoch: ', year_epoch), textposition = "none") %>% 
      layout(yaxis = list(title = "Project count", zeroline = T, tickformat = "digit"), showlegend = T,
             legend = list(orientation = "h",
                           x =0.5, xanchor = "center",
                           y = 1, yanchor = "bottom"),
             xaxis = list(title = xlegend, tickangle = 300, showticklabels = TRUE, tickfont = list(size = 12),
                          categoryorder = "array", categoryarray = ~ reorder(year_epoch, AppCount)),
             barmode = 'stack', autosize = F, title= list(text = paste0(input$platform),x = 0))
  } else {
    req(input$site)
    if ((input$site %in% "Merge")) {
      react_input_grp_App_Merge() %>%
        plot_ly(x = ~year_epoch, y = ~value_sum/1e9, width = 1200, height = 700,
                type = 'bar', split =~Application, 
                hoverinfo = 'text',
                text = ~paste0('</br> App: ', Application,
                               '</br> Value: ', round(value_sum/1e9, 2)," Gb",
                               '</br> Epoch: ', year_epoch), textposition = "none") %>% 
        add_trace(y=~Application, showlegend = FALSE) %>%
        layout(yaxis = list(title = ylegend, zeroline = T, tickformat = "digit"), showlegend = T,
               legend = list(orientation = "h",
                             x =0.5, xanchor = "center",
                             y = 1, yanchor = "bottom"),
               xaxis = list(title = xlegend, tickangle = 300, showticklabels = TRUE, tickfont = list(size = 12),
                            categoryorder = "array", categoryarray = ~ reorder(year_epoch, value_sum)),
               barmode = 'stack', autosize = T, title= list(text = paste0(input$platform),x = 0))
      
    } else if ((input$site %in% "Split")) {
      CT <- react_input_grp_App_Split() %>% 
        filter(Site %in% c("Farmington", "CT")) %>%
        plot_ly(x = ~year_epoch, y = ~value_sum/1e9, width = 1200, height = 700,
                type = 'bar', split =~Application, showlegend = F,
                hoverinfo = 'text',
                text = ~paste0('</br> App: ', Application,
                               '</br> Value: ', round(value_sum/1e9, 2)," Gb",
                               '</br> Epoch: ', year_epoch), textposition = "none") %>% 
        add_trace(y=~Application, showlegend = F) %>%
        layout(xaxis = list(title = "Farmington", tickangle = 300, showticklabels = TRUE, 
                            tickfont = list(size = 12),
                            categoryorder = "array", categoryarray = ~ reorder(year_epoch, value_sum)),showlegend = F)
      
      BH <- react_input_grp_App_Split() %>% 
        filter(Site %in% c("Bar Harbor", "BH")) %>%
        plot_ly(x = ~year_epoch, y = ~value_sum/1e9, width = 1200, height = 700,
                type = 'bar', split =~Application, 
                hoverinfo = 'text',
                text = ~paste0('</br> App: ', Application,
                               '</br> Value: ', round(value_sum/1e9, 2)," Gb",
                               '</br> Epoch: ', year_epoch), textposition = "none") %>% 
        add_trace(y=~Application, showlegend = F) %>%
        layout(xaxis = list(title = "Bar Harbor", tickangle = 300, showticklabels = TRUE, tickfont = list(size = 12),
                            categoryorder = "array", categoryarray = ~ reorder(year_epoch, value_sum)), 
               showlegend = F)
      
      subplot(CT, BH, titleX = TRUE, shareY = T) %>%
        layout(yaxis = list(title = ylegend, zeroline = T, tickformat = "digit"), 
               showlegend = F,
               legend = list(orientation = "h",
                             x =0.5, xanchor = "center",
                             y = 1, yanchor = "bottom"),
               barmode = 'stack', autosize = F, title= list(text = paste0(input$platform),x = 0))
    }
  }
})