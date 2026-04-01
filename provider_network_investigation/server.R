
## server from visnetwork documetnation 

# --- Shiny Server ---
server <- function(input, output, session) {
  
  
  # #Filter data based on chosen specialty
  # df_for_plot <- reactive({
  #   req(input$pcp_specialty)
  # if(input$pcp_specialty == "All"){
  #   df_for_plot <- hop_referral_pcp_hosp
  # } else if(input$pcp_specialty != "All"){
  #   df_for_plot <- hop_referral_pcp_hosp |> 
  #     filter(pcp_class == input$pcp_specialty)
  # }
  # })
  
  #Sarah code---------- FOR NETWORK GRAPH
  output$network_plot <- renderVisNetwork({
    # Render the network using renderVisNetwork
    
    ##------- filter data based on chosen value 
    #set default
    df_for_plot <- hop_referral_pcp_hosp
    
    df_for_plot <-
      if(input$pcp_specialty == "All"){
        df_for_plot <- hop_referral_pcp_hosp
      } else if(input$pcp_specialty != "All"){
        df_for_plot <- hop_referral_pcp_hosp |>
          filter(pcp_class == input$pcp_specialty)
      }
    
    #--- Prepare dataset for EDGES --------------------------------------
    #Select only the 'to' and 'from' npi from the dataset, and the number of patients for the edges
    data_for_edges <- df_for_plot |> 
      select(to_npi, from_npi, patient_count)
    ### Create a smaller width size by dividing all patient number by 100, which makes visual graphing easier 
    clean_data_for_edges <- data_for_edges |> mutate(width_100 = round(patient_count/100))
    
    #clean_data_for_edges <- data_for_edges |> select(from, to, width_100)
    colnames(clean_data_for_edges) <- c('from', 'to', 'title', 'width')
    
    ## add in a text information to the 'title' column so that the figure has clear labeling
    clean_data_for_edges<- clean_data_for_edges |> mutate(title= paste("patients: ", title))
    
    
    #--- Prepare dataset for NODES ----------------------------------------
    ## filter out only the columns needed before the merge
    #take out only the columns with the pcp npi and name from the dataframe
    name_for_nodes <- df_for_plot |> select(from_npi, full_name)
    
    # merge it into the node in order to make it a 'label'
    pcp_id_node <- left_join(patients_community_id, name_for_nodes, by= join_by (npi == from_npi))
    
    
    ## repeat but for to_npi 
    name_for_nodes <- df_for_plot |> select(to_npi, to_organization)
    
    hosp_pcp_id_node <- left_join(pcp_id_node, name_for_nodes, by= join_by (npi == to_npi))
    hosp_pcp_id_node
    
    #pull out only values needed for the graphing
    clean_data_for_node <- hosp_pcp_id_node |>
      #Add a new column that pulls all the not-null values from the to_npi and from_npi merges
      mutate(label = tolower(coalesce(full_name, to_organization))) |>
      #pull out only the columns necessary for the nodes
      select(npi, communityId, label) |>
      #drop duplicates produced by the merge
      distinct()
    
    #replace the community ID with the descriptive names
    clean_data_for_node <- clean_data_for_node |>
      mutate(community_name = recode(communityId, !!!name_for_cid))
    
    #pull out only the columns needed for graping
    clean_data_for_node <- clean_data_for_node |> select(npi,community_name, label)
    
    #rename to match name formating for graphing
    colnames(clean_data_for_node) <- c("id", "group", "title")
    
    #add a blank label column to remove the text on the graphing
    clean_data_for_node <- clean_data_for_node |> mutate(label= "")
    
    #remove duplicate id
    clean_data_for_node <- clean_data_for_node |> distinct()
    
    ##--- Input data into Visnetwork graph -----------------
    visNetwork(clean_data_for_node, clean_data_for_edges, width="100%") |> #, width="100%"
      #create the graph
      visIgraphLayout() |>
      #change visual format for nodes
      visNodes(shape= 'dot') |>
      #change visual format for edges
      visEdges(color='gray') |>
      #Create a drop down menu 
      visOptions(highlightNearest = list(enabled = T, degree = 1, hover = T),
                 #Sets which table variable to group based on a drop-down menu
                 selectedBy = "group") |> 
      #define the starting seed so it groups the same way each time 
      visLayout(randomSeed=1) |>
      #create global for all groups
      visGroups() |>
      #add a legend 
      visLegend() |> 
      #add navigation tools 
      visInteraction (navigationButtons = TRUE) |> 
      visClusteringByGroup(groups, force= TRUE) |>
      #visConfigure(enabled = TRUE) |>
      #add code to make dot clustering easier (so there is no overlap)
      visPhysics(stabilization = FALSE, solver = "barnesHut", barnesHut = list(gravitationalConstant = -10000))
  }) #close visrenderplot
  
  ##---- ADD DATA TABLE AT BOTTOM ------ 
  #output$selectedTable <- renderDataTable({
  #})
  
  
  
  
  ##------ Anitha Code----------------
  
  #anitha code-----------
  filtered_data <- reactive({
    req(input$specialtyPicker)
    hop_referral_pcp_hosp %>%
      filter(!is.na(pcp_special) & (pcp_special %in% input$specialtyPicker))
    
  })
  output$demographicsCirclePlot <- renderPlotly({
    data <- filtered_data()
    req(nrow(data) > 0)
    
    # Determine cluster centers using k-means
    # k = number of unique hospital communities
    k <- length(unique(data$hospital_communityid))
    
    # Assign numeric ID to each hospital community
    data$hospital_factor <- as.numeric(factor(data$hospital_communityid))
    
    # Run k-means on the hospital IDs to get cluster centers
    set.seed(123)  # for reproducibility
    km <- kmeans(data$hospital_factor, centers = k)
    
    plot_data <- data %>%
      mutate(
        cx = km$centers[km$cluster],   # cluster center x
        cy = km$cluster * 3,           # cluster center y, spaced vertically
        x = cx + rnorm(n(), 0, 0.5),   # spread within cluster
        y = cy + rnorm(n(), 0, 0.5)
      )
    
    # Compute circle vertices (optional if you want polygon shapes)
    #vertices <- circleLayoutVertices(all_circles, npoints = 50)
    # Plotly scatter
    p <- plot_ly(
      data = plot_data,
      x = ~x,
      y = ~y,
      type = 'scatter',
      mode = 'markers',
      color = ~as.factor(hospital_communityid),
      colors= rainbow(13),
      marker = list(
        size = ~sqrt(patient_count)*2,
        # color = ~as.factor(hospital_communityid),
        # colors= "Viridis",
        line = list(width = 1, color = 'black'),
        opacity = 0.7
      ),
      text = ~paste(
        "Hospital:", to_organization,
        "<br>PCP:", full_name,
        "<br>Specialty:", pcp_special,
        "<br>Patients:", patient_count,
        "<br>Transactions:", transaction_count,
        "<br>Avg Wait Days:", round(average_day_wait, 1)
      ),
      hoverinfo = "text",
      showlegend = FALSE
    )
    p %>%
      layout(
        xaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
        yaxis = list(title = "", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
        plot_bgcolor = '#F8F8F8',
        xaxis = list(
          zerolinecolor = '#ffff',
          zerolinewidth = 2,
          gridcolor = 'ffff'),
        yaxis = list(
          zerolinecolor = '#ffff',
          zerolinewidth = 2,
          gridcolor = 'ffff'))
  })#render plotly
} #closer server page

