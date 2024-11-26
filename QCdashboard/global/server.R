server <- function(input, output, session) {
  module1_Server("Module1")
  auth <- callModule(
    module = auth_server,
    id = "auth",
    check_credentials = check_credentials(
      db = user_database_info,
      passphrase = passphrase),
    session = shiny::getDefaultReactiveDomain()
  )
  
  observe({
    req(auth$user)
    shinyjs::show("fab_btn_div")
  })
  observeEvent(session$input$logout,{
    session$reload()
  })
  #output$res_auth <- renderPrint({
  #  reactiveValuesToList(auth)
  #})
  observeEvent(input$refresh, {
    refresh()
  })
  module2_Server("Module2")
}
