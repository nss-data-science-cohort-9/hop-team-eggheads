
fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),

  titlePanel("Living in the Lego World"),

  navbarPage(
    title = "Living in the Lego World",

    tabPanel(
      "Demographics",

      sidebarLayout(
        sidebarPanel(
          pickerInput(
            "specialtyPicker",
            "Choose PCP Specialty:",
            choices = unique(hop_referral_pcp_hosp$pcp_special),
            multiple = TRUE,
            options = list(`actions-box` = TRUE)
          )
        ),

        mainPanel(
          plotlyOutput("demographicsCirclePlot", height = "700px")
        )
      )
    )
  )
)