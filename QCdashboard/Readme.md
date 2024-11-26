## Quick summary

*The QC metrics dashboard was built based on R ShinyApp code. The entire code is modularized for ease of management and efficiency. Therefore, changes should be made to only the intended section of the code. For instance, if update is needed to the landing page UI, only access the file containing that code. Ensure backup of the code before applying changes.*

## App location
    ctgenometech03.jax.org:/srv/shiny-server

## Users database directory
    ./.userdatabase
        all input files are located in this directory
## Adding new users 
    .addNewUser.R :
        edit the "New user information" rows and launch <Rscript .addNewUser.R> to add the user to the database. 
## Adding new users 
        To be added
## Server stats 
        To be added
## QC metrics files directory
    ./.InputDatabase
        database containing users login information is hiding in this directory

## App structure
    files
        app.R :
            sourced all server codes in the sequence at which they will appear if they were to be in single file. 
        restartAppAfterCodeUpdate.sh :
            launch to restart the server. Running this code may be neccesary following an update so that changes is reflected on the interface. Note that during launch, server will be offline.
    
    folders
        ./libraries
            - libraries.R :
                    list of all installed libraries needed for the server to function
        ./loginAuth
            - auth.R :
                    handles users login (authentication) page. Code is sourced inside modules/dashboardAuthHeaderUI.R
            - labels.R :
                    custom login page text
            - user_info.R :
                    path to database containing user's login information
            - logoutButton.R :
                    logout appearance. Code is sourced inside modules/dashboardAuthHeaderUI.R
        ./input
            - inputFiles.R :
                    read content of QC metrics input files
            - sample_size.R :
                    calculate total samples in the database
        ./modules
            - landingPageUI.R :
                    landing page code used for users interface
            - landingPageServer.R :
                    landing page server code that process landingPageUI.R
            - dashboardSideBarUI.R :
                    main dashboard side menu code. Everything in side panel is here
            - dashboardBodyUI.R :
                    main dashboard body code. 
            - dashboardAuthHeaderUI.R :
                    main dashboard code that handles what is displayed in header, body and sidebar. It also sourced auth.R and logoutButton.R
            - dashboardServer.R :
                    main dashboard server code that handles all dashboard UI codes. (TO DO: create separate plotting code to be sourced here)
        ./plot : 
                DashboardPlotCode.R :
                        plotting functions sourced within dashboardServer.R
                landingPagePlotCode.R :
                        plotting functions sourced within landingPageServer.R
        
        ./global -  this is where all the modules are tied. 
            ui.R : 
                handles all UI modules as it should appear on interface
            server.R :
                handles all server modules. Must be set to effectively interract with all servers.

## Admin console
    adminConsole.R : This code is being worked upon. Not useful at the moment. If SSO goes live, this code will not be useful.

## Logs directory
    /var/log/shiny-server:
            All shinyApp log files are located in this directory 
    Changing directory:
            Shiny server logs information can be changed within the config file located at /etc/shiny-server/shiny-server.conf. **Take caution when applying changes**

## Images
        ./www :
                All images are in this folder. do not change www
