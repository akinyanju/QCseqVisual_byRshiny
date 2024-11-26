auth_ui(
  id = "auth",
  tags_top =
    tags$div(
      tags$h3("For gatekeeper use only!", 
              style="align:left;position:relative;bottom:-0px;margin:0;color:coral;font-family:arial; font-style:bold"),
      tags$img( src = "GTlogo.png", width = 50)),
  # add information on bottom ?
  tags_bottom = 
    tags$div(
      actionButton("refresh", "back", style = "align:right;position:relative;bottom:10px;color:#00008B; background-color:white; width: 85px; font-size: 18px;", 
                   class="col-sm-12", icon("angle-left")),
      tags$h4("Contact: gtdrylab@jax.org", style="text-align:right;bottom:-0px;margin:0;color:black;font-family:arial; font-style:italic;")
    ),
  background  = "linear-gradient(rgba(23, 78, 184, 1),
                       rgba(0, 0, 0, 0)),
                       url('/JAXlogo.png');",  #https://rgbacolorpicker.com/
  lan = use_language("en"), enable_admin = TRUE
)