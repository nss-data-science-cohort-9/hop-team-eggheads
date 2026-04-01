#pcp_hosp <- read_csv("data/hop_referral_pcp_hosp.csv")

# # # # # # 
# THEIR GLOBAL
# # # # # #
#install.packages("here")
#install.packages("shinyWidgets")
#install.packages("shinycssloaders")
#install.packages("highcharter")
#install.packages("plotly")
#install.packages("packcircles")
library(tidyverse)
library(here)
library(dplyr)
library(tidyr)
library(tibble)
library(ggplot2)
library(shiny)
library(shinyWidgets)
library(shinycssloaders)
#library(igraph)
#library(ggraph)
library(scales)
library(DT)
library(highcharter)
library(purrr)
library(stringr)
#library(fuzzyjoin)
#library(lexicon)
#library(visNetwork)
library(httr)
#library(rdrop2)
library(lubridate)
library(plotly)
library(packcircles)

hop_referral_pcp_hosp <- read.csv("../data/hop_referral_pcp_hosp.csv")

hop_referral_pcp_hosp_clean <- hop_referral_pcp_hosp %>%
  mutate(
    part.id = row_number(),
    part.name = paste(full_name, "-", pcp_class),
    theme.name = to_organization,
    num.parts = patient_count
  )

# Color mapping
hospital_colors <- RColorBrewer::brewer.pal(9, "Set1")

hop_referral_pcp_hosp_clean <- hop_referral_pcp_hosp_clean %>%
  mutate(color.hex = hospital_colors[as.numeric(as.factor(hospital_communityid))])

