#load libraries ------
library(tidyverse)
library(ggplot2)
library(data.table)
library(dplyr)
library(plotly)
library(igraph)
library(igraphdata)
library(visNetwork)
library(tidyverse)
library(shiny)
library(glue)
library(DT)
library(plotly)
library(bslib)
#--------------

#load dataset
hop_referral <- read_csv("data/provider_network_nash_cbsa.csv")
patients_community_id <- read_csv("data/neo4j_query_table_data_patients.csv")


#----------------------------
#Merge community ID with hop_referral dataset
#------------------------------
#merge from_npi community
hop_referral_merged <- merge(
  hop_referral,
  
  patients_community_id,
  by.x = "from_npi", by.y = "npi"
)

#rename columns 
hop_referral_merged_pcp <- rename(hop_referral_merged, c("pcp_communityid" = "communityId"))

#Merge to_npi community id
hop_referral_merged_pcp_hosp <- merge(
  hop_referral_merged_pcp,
  patients_community_id,
  by.x = "to_npi", by.y = "npi"
)
#rename columns 
hop_referral_pcp_hosp <- rename(hop_referral_merged_pcp_hosp, c("hospital_communityid" = "communityId"))

#---------
#create community ID with hospital group informaiton 
#----------
#VUMC community ids
vumc_id<- hop_referral_pcp_hosp %>% 
  filter(
    to_organization == "VANDERBILT UNIVERSITY MEDICAL CENTER"
  ) %>% 
  distinct(
    hospital_communityid
  ) |> pull()
vumc_id

#HCA community ids
HCA_id<- hop_referral_pcp_hosp %>% 
  filter(
    to_organization == "HCA HEALTH SERVICES OF TENNESSEE, INC."
  ) %>% 
  distinct(
    hospital_communityid
  ) |> pull()
HCA_id

#st thomas community ids
ST_id<- hop_referral_pcp_hosp %>% 
  filter(
    to_organization == "SAINT THOMAS WEST HOSPITAL"
  ) %>% 
  distinct(
    hospital_communityid
  ) |> pull()
ST_id

#pull out all remaining ids 
exclude_chain_id <- c(vumc_id, HCA_id, ST_id)
exclude_chain_id
#create a list of the community ids that correspond to other hospitals
single_community_id <- hop_referral_pcp_hosp |> filter(!(hospital_communityid %in% exclude_chain_id)) |> distinct(hospital_communityid) |> pull()
single_community_id

#compare the overlap and define community id groups
#pull out community id that is exclusively vumc
only_vumc <- setdiff(vumc_id, c(HCA_id, ST_id))
only_vumc

#pull out community id that is exclusively hca
only_HCA <- setdiff(HCA_id, c(vumc_id, ST_id))
only_HCA

#pull out community id that is exclusively ST
only_ST <- setdiff(ST_id, c(vumc_id, HCA_id))
only_ST

#pull out the community id that is SHARED between VUMC and any other hospital
vumc_overlap <- setdiff(exclude_chain_id, c(only_vumc, only_HCA, only_ST))
vumc_overlap

#create a final descriptive list (like a dictionary) to make a more unique name 
name_for_commuityid<- c("VUMC" = only_vumc, 
                        "VUMC shared"= vumc_overlap, 
                        "HCA" = only_HCA, 
                        "St thomas" =only_ST, 
                        "community 1" = single_community_id[1], 
                        "community 2" = single_community_id[2], 
                        "community 3" = single_community_id[3], 
                        "community 4" = single_community_id[4],
                        "community 5" = single_community_id[5],
                        "community 6" = single_community_id[6],
                        "community 7" = single_community_id[7])
name_for_commuityid


#switch the order 
name_for_commuityid <- setNames(names(name_for_commuityid), name_for_commuityid)
name_for_commuityid


#---------------
#create nodes and visuals 
#------------------







