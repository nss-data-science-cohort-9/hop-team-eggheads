## Ui base from visNetwork documentation
ui <- page_navbar(
  #Heading format
  title= "Hop team test",
  bg = "#460e06",
  inverse= TRUE,

  ########
  #Tab 1: full party modeling
  #######
  nav_panel(
    title="Full party",
    fluidRow(
      #Panel: Sidebar for character selection -----
      column(
        width = 2,
        h2("Select specialty"),

        #character 1-------
        fluidRow(
          column(12,
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
                 ))), #close selection 1

      ), #close sidebar column
      #Mainpanel: model figure and monster scatter plot -----
      column(
        width= 10,
        # Output element for the network visualization
        visNetworkOutput("network_plot"),
        
        #----## CODE TO ADD TABLE FROM SELECTION------
        dataTableOutput("selectedTable")
      ) #close main panel column
    ) #close full page fluid row
  ) #close nav_panel
) #close whole page_nav