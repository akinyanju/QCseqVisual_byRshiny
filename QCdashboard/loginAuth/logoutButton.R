shinyjs::hidden(tags$div(id = "fab_btn_div",
                         fab_button(
                           actionButton(
                             position = "bottom-right",
                             animation = "fountain",
                             toggle = "hover",
                             inputId = "logout",
                             label = "Logout",
                             tooltip = "Logout",
                             icon = icon("sign-out")
                           )
                         )
)
)