module2_header_side_body <- function() {
  # authentication module
  tagList(
    shinyjs::useShinyjs(),
    source("/srv/shiny-server/loginAuth/auth.R")[1], #Ucomment this code. #authentication code is sourced here
    source("/srv/shiny-server/loginAuth/logoutButton.R")[1], 
    #source("/Users/lawalr/Dropbox/My-script/AssociateCompSci/RshinyModules/loginAuth/auth.R")[1],
    #source("/Users/lawalr/Dropbox/My-script/AssociateCompSci/RshinyModules/loginAuth/logoutButton.R")[1],
    verbatimTextOutput(outputId = ("res_auth")),
    ############################################################################################################
    ##CODE DELETION ENDS HERE
    ############################################################################################################
    shinydashboard::dashboardPage(
      #Header content
      header = shinydashboard::dashboardHeader(
        title = "GT QC Dashboard",tags$li(class = "dropdown",
                                          tags$style(".main-header {max-height: 60px}"),
                                          tags$style(".main-header .logo {height: 60px}")),
        dropdownMenu(type = "task", badgeStatus = "success", icon = icon("info", "fa-2x"),
                     headerText = "Percent application (samples) in database",
                     taskItem(value = round(((length(unique(atacseq$Sample_Name))/total_database_samples)*100),2), color = "green","atacseq"),
                     taskItem(value = round(((length(unique(basic$Sample_Name))/total_database_samples)*100),2), color = "green","basic"),
                     taskItem(value = round(((length(unique(chic$Sample_Name))/total_database_samples)*100),2), color = "green","chic"),
                     taskItem(value = round(((length(unique(ctp$Sample_Name))/total_database_samples)*100),2), color = "green","ctp"),
                     taskItem(value = round(((length(unique(pdxrnaseqR2$Sample_Name))/total_database_samples)*100),2), color = "green","pdxrnaseqR2"),
                     taskItem(value = round(((length(unique(rnaseq$Sample_Name))/total_database_samples)*100),2), color = "green","rnaseq"),
                     taskItem(value = round(((length(unique(rrbs$Sample_Name))/total_database_samples)*100),2), color = "green","rrbs"),
                     taskItem(value = round(((length(unique(wgbs$Sample_Name))/total_database_samples)*100),2), color = "green","wgbs"),
                     taskItem(value = round(((length(unique(chipseq$Sample_Name))/total_database_samples)*100),2), color = "green","chipseq" ),
                     taskItem(value = round(((length(unique(pdxrnaseq$Sample_Name))/total_database_samples)*100),2), color = "green","pdxrnaseq"),
                     taskItem(value = round(((length(unique(pdxwgs$Sample_Name))/total_database_samples)*100),2), color = "green","pdxwgs"),
                     taskItem(value = round(((length(unique(rnaseqR2$Sample_Name))/total_database_samples)*100),2), color = "green","rnaseqR2"),
                     taskItem(value = round(((length(unique(wes$Sample_Name))/total_database_samples)*100),2), color = "green","wes"),
                     taskItem(value = round(((length(unique(wgs$Sample_Name))/total_database_samples)*100),2), color = "green","wgs" )
        ),
        dropdownMenu(type = "task",icon = icon("question", "fa-2x"), headerText = "",
                     messageItem( from = "Email GTdrylab for help", message = "gtdrylab@jax.org")),
        tags$li(img(src="GTlogo.png"), style = "padding-top:0px; padding-bottom:0px;",class = "dropdown")
      ),
      ## Sidebar content -
      sidebar = shinydashboard::dashboardSidebar(module2_sidebar_UI("Module2")),
      ## Body content
      body = shinydashboard::dashboardBody((module2_body_UI("Module2"))
      )
    )
  )
}
