#shinyServer(function(input, output, session) {
  
  #############################################################################
  #############################################################################
  ## Data                                                                    ##
  #############################################################################
  #############################################################################
  
  
  #############################################################################
  #############################################################################
  ## Demographics                                                            ##
  #############################################################################
  #############################################################################
  
  #############################################################################
  # Gender and ethnicity                                                      #
  #############################################################################
  

function(input, output, session) {

  filtered_data <- reactive({
    req(input$specialtyPicker)
    hop_referral_pcp_hosp %>%
      filter(pcp_special %in% input$specialtyPicker)
  })

  output$demographicsCirclePlot <- renderPlotly({

    data <- filtered_data()
    req(nrow(data) > 0)

    # Initialize empty dataframe for circle positions
    all_circles <- data.frame()

    # Process each hospital separately
    for(hospital_id in unique(data$hospital_communityid)) {
      sub <- data %>% filter(hospital_communityid == hospital_id)
      packing <- circleProgressiveLayout(sub$patient_count, sizetype = 'area')
      sub <- cbind(sub, packing)
      all_circles <- rbind(all_circles, sub)
    }

    # Compute circle vertices (optional if you want polygon shapes)
    vertices <- circleLayoutVertices(all_circles, npoints = 50)

    # Plotly scatter
    p <- plot_ly(
      data = all_circles,
      x = ~x,
      y = ~y,
      type = 'scatter',
      mode = 'markers',
      marker = list(
        size = ~sqrt(patient_count)*2,
        color = ~factor(hospital_communityid),
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
        plot_bgcolor = '#f8f8f8'
      )

  })
}