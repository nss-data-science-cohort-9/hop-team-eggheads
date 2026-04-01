

page_navbar(
  #Heading format
  title= "Provider Network Investigation",
  bg = "#460e06",
  inverse= TRUE,
  ######
  #Tab 1- Bubble Plot (Anitha)
  #######
  nav_panel(
    title="Bubble Plot",
    sidebarLayout(
      sidebarPanel(
        pickerInput(
          "specialtyPicker",
          "Choose PCP Specialty:",
          choices = unique(hop_referral_pcp_hosp$pcp_special),
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
  
  ########
  #Tab 2: Network plot (Sarah)
  #######
  nav_panel(
    title="Network connections",
    sidebarLayout(
      #Panel: Sidebar for selection -----
      sidebarPanel(
        selectInput(
          "pcp_specialty",
          "provider specialty:",
          #Automatically fill option based on unique class column variables
          choices = c(
            #An option to see everything (not filter by specialty) 
            "All", 
            #take out all specialty options as a list
            hop_referral_pcp_hosp |>  
              distinct(pcp_class) |> 
              pull() |> sort()),
          #set a default value to generate base figure
          selected = "All"
        ) #close selection 1
      ), #close sidebar column
      mainPanel(
        # Output element for the network visualization
        #visNetworkOutput("network_id", height = "100%", width = "100%")
        visNetworkOutput("network_plot", height = "100%", width = "100%")
        #visNetworkOutput("network_plot", 
                         #width = "700px", 
                         #height = "700px")
        
        #----## CODE TO ADD TABLE FROM SELECTION------
        #dataTableOutput("selectedTable")
      ) #close main panel column
    ) #close sidebar layout
  ) #close out nav_panel
) #close whole page
