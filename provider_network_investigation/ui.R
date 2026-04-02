
page_navbar(
  #Heading format
  title= "Provider Network Investigation",
  bg = "#460e06",
  inverse= TRUE,
  
  ######
  #Tab- Project information
  #######
  nav_panel(title="Project information",
            tabPanel(
              "Overview",
              tags$h1("Scope"),
              tags$p(HTML("THIS TOOL IS VALUABLE FOR A HOSPITAL TO UTILIZE IN ORDER TO SEE WHERE THERE IS ROOM FOR GROWTH.")),
              tags$p(HTML("Here is a second paragraph.")),
              tags$h1("Approach"),
              tags$p(HTML("HERE is the text to describe our approach"))
            ) #close tab panel
  ), #close nav_panel
  
  ########
  #Tab 2: Network plot [BIG PICTURE]
  #######
  nav_panel(
    title="Network connections",
    fluidRow(
      #Panel: Sidebar for selection -----
      # column(
      #   width = 2,
      #   h2("Select party build"), 
      #   fluidRow(
      #     column(12,
      #            selectInput(
      #              "pcp_specialty",
      #              "provider specialty:",
      #              #Automatically fill option based on unique class column variables
      #              choices = c(
      #                #An option to see everything (not filter by specialty) 
      #                "All", 
      #                #take out all specialty options as a list
      #                hop_referral_pcp_hosp |>  
      #                  distinct(pcp_special) |> 
      #                  pull() |> sort()),
      #              #set a default value to generate base figure
      #              selected = "All"
      #            ))), #close section 1
      # ), #close sidebar column
      #Mainpanel: model figure and monster scatter plot -----
      column(
        width= 12, 
        visNetworkOutput("network_plot", 
                         height = "700px", 
                         width = "100%")
      ) #close main panel column 
    ) #close full tab fluid row
  ), #close nav panel
  
  ######
  #Tab- Bubble Plot (Anitha)
  #######
  nav_panel(
    title="Bubble Plot",
    sidebarLayout(
      sidebarPanel(
        pickerInput(
          "specialtyPicker",
          "Choose PCP Specialty:",
          choices = unique(hop_referral_pcp_hosp$pcp_special),
          #set default selected value to 'All'
          selected= unique(hop_referral_pcp_hosp$pcp_special),
          multiple = TRUE,
          options = list(`actions-box` = TRUE)
        )
      ), #close sidebar layout
      mainPanel(
        plotlyOutput("demographicsCirclePlot", 
                     height = "700px")
      )#close mainPanel
    ) #close sidebarlayout
  ), #close nav_panel
  
  ######
  #Tab- Summary Bar Plot (Cat)
  #######
  nav_panel(
    title="Summary bar plot",
    sidebarLayout(
      # Sidebar panel for controls.
      sidebarPanel(
        pickerInput(
          "demographicsMeasurePicker",
          "Choose PCP Specialty:",
          choices = unique(hop_referral_pcp_hosp$pcp_special),
          #set default selected value to 'All'
          selected= unique(hop_referral_pcp_hosp$pcp_special),
          multiple = TRUE,
          options = list(`actions-box` = TRUE)
        ), #close picker
        tags$p(HTML("<b>BOLD TEXT </b> Type in description for dropdown here."))
      ), #close side bar panel
      
      # Main panel with plot.
      mainPanel(
        highchartOutput("demographicsDiversity",
                        width = "700px", height = "2000px")
      )# close main panel
    )#close sidebar panel
    ) #close sidebar layout
  ) #close nav_panel
#)
  