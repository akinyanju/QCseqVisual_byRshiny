library(shiny)
library(shinymanager)
library(shinyWidgets)

###Login page labels
admin_label <- set_labels(
  language = "en",
  "Please authenticate" = "Admin console page",
  "Username:" = "Username",
  "Password:" = "Password"
)
  

######################################################
#Must be provided on ctgenometech
user_database_info="/srv/shiny-server/.userdatabase/.userdatabase.sqlite"
passphrase = "gtdrylab1900"
#user_database_info="/Users/lawalr/Library/CloudStorage/Box-Box/GT-Analyses/Rshiny/user_pwd_database.sqlite"
#passphrase = key_get("R-shinymanager-key", "obiwankenobi")
##############################################################Side function
ui <- secure_app(
  enable_admin = TRUE,
  head_auth = NULL,
  theme = NULL,
  fab_position = "bottom-right", 
  background  = "linear-gradient(rgba(7, 2, 5, 1), 
                    rgba(7, 2, 5, 1))",
  fluidPage(tags$h2("If you are not the admin, this is how much you will see. Only the admin can hover into the backend", 
                    style="text-align:center;color:white;"),
            tags$style('.container-fluid {
                             background-color: #0b7ba3;
              }'),
            setBackgroundColor("black")),
  verbatimTextOutput(("res_auth"))
)
               
 

######################################################Server
#module3_admin_Server <- function() {
#  moduleServer(
#    function(input, output, session) {
server = function(input, output, session) {
  ######################################################Path to database. Will not accept key_get on ctgenome
  result_auth <- secure_server(check_credentials = check_credentials(
    db = user_database_info,
    passphrase = passphrase),
    timeout = 5,
    inputs_list = NULL, 
    validate_pwd = NULL,
    session = shiny::getDefaultReactiveDomain())
  
  output$res_auth <- renderPrint({
    reactiveValuesToList(result_auth)
  })
  
  observe({
    print(input$shinymanager_where)
  })
}

shinyApp(ui=ui, server=server)


