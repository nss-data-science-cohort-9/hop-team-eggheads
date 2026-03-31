
## server from visnetwork documetnation 

# --- Shiny Server ---
server <- function(input, output, session) {
  output$network_plot <- renderVisNetwork({
  # Render the network using renderVisNetwork
    #----- filter base dataset based on user input 
    #filter based on specialty choice
    
    #define this as the default
    df_for_plot <- hop_referral_pcp_hosp
    
    if(input$pcp_specialty != "All"){
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
    clean_data_or_node <- clean_data_for_node |>
      mutate(community_name = recode(communityId, !!!name_for_commuityid))
    
    #pull out only the columns needed for graping
    clean_data_for_node <- clean_data_for_node |> select(npi,community_name, label)
    
    #rename to match name formating for graphing
    colnames(clean_data_for_node) <- c("id", "group", "title")
    
    #add a blank label column to remove the text on the graphing
    clean_data_for_node <- clean_data_for_node |> mutate(label= "")
    
    #remove duplicate id
    clean_data_for_node <- clean_data_for_node |> distinct()
    
    ##--- Input data into Visnetwork graph -----------------
    visNetwork(clean_data_for_node, clean_data_for_edges, width="100%") |> 
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
      
      #add code to make dot clustering easier (so there is no overlap)
      visPhysics(stabilization = FALSE, solver = "barnesHut", barnesHut = list(gravitationalConstant = -10000))
  }) #close 
} #closer server output$network_plot

##---- ADD DATA TABLE AT BOTTOM ------ 
#output$selectedTable <- renderDataTable({
#})

#   ### [Create data table on the main page]
#   output$selectedTable <- renderDataTable({
#     
#     
#     #Create monster plot calculations, same process as earlier-------------------
#     #create the 4-party list based on selected values 
#     full_build_select_party = c(input$class_variable_1, 
#                                 input$class_variable_2, 
#                                 input$class_variable_3, 
#                                 input$class_variable_4)
#     
#     #Create title
#     title <- glue("Monster challenge rating based on 4-party total damage output")
#     
#     #Create the total party damage prediction graph based on the selected class variables---------------
#     #filter out selected builds from the full simulation data 
#     
#     only_party_sim <- sim_results |> 
#       filter(build_name %in% full_build_select_party)
#     
#     #for each target_ac, add up all the damage from EACH encounter across the whole party 
#     ## groupby by encounter number, than sum all the 'total damage'
#     
#     party_combo_sim <- only_party_sim |> 
#       group_by(target_ac, encounter_num) |> 
#       summarise(total_party_damage= sum(total_dmg), 
#                 .groups = "drop")
#     
#     ## Create summary dataframe based on distrubution of combined encounter modeling
#     total_dmg_dist <- party_combo_sim |>
#       group_by(target_ac) |>
#       summarize(min_val = min(total_party_damage),
#                 max_val = max(total_party_damage),
#                 q25= quantile(total_party_damage, 0.25),
#                 median= median(total_party_damage),
#                 q75= quantile(total_party_damage, 0.75))
#     
#     ## Create monster challenge rating based on where the HP falls on the total_damage distribution
#     #rename monster column for easier merging
#     monster_data_merge <- monster_data_maxac |>
#       rename(target_ac = AC)
#     
#     #merge the summary stats with monster info based on AC
#     mon_with_party_stat <- left_join(monster_data_merge,
#                                      total_dmg_dist,
#                                      by = "target_ac")
#     #rename AC column for easier graphing
#     mon_with_party_stat <- mon_with_party_stat |> rename(AC= target_ac)
#     
#     #create a challenge rating using case_when based on the summary statistics
#     mon_party_challenge <- mon_with_party_stat |>
#       mutate(challenge_rate = case_when (HP<q25 ~ 'easy',
#                                          HP >=q25 & HP <= q75 ~ 'moderate',
#                                          HP > q75 & HP <= (2*max_val)~ 'hard',
#                                          HP >= (2*max_val) ~'impossible')
#       )
#     
#     #convert challenge rating to a factor value
#     mon_party_challenge <- mon_party_challenge|>
#       mutate (challenge_rate= as.factor(challenge_rate))
#     
#     #update dataframe for table widget with challenge rating 
#     monster_challenge <- mon_party_challenge |> relocate(challenge_rate) |> rename("challenge rating"= challenge_rate) 
#     
#     #Table: Show monster stats with challenge rating -----------------------------------------
#     selected_data <- monster_challenge
#     
#     # ## update displayed data table based on plotly selection
#     # selected_data <- reactive({
#     #   # Get the selected points' keys from plot with source "A"
#     #   event_data_selected <- event_data(event = "plotly_selected",
#     #                                     source = "chmon")
#     #
#     #   #Create a condition to filter data table based on ggplot selection
#     #   if (is.null(event_data_selected)) {
#     #     # Return all data if nothing is selected or the selection is cleared
#     #     return(monster_data_maxac)
#     #   }
#     #   else {
#     #     selected_keys <- event_data_selected$key
#     #     # Filter the original data frame to keep only selected rows
#     #     monster_data_maxac |>
#     #       filter(Name %in% selected_keys)
#     #   }
#     # })
#     
#     #view table based on previous conditionals
#     selected_data
#   }) #Datatable section