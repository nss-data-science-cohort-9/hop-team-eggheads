# Hop Teaming Analysis: Nashville Referral Network

## Overview
In this project, you will analyze referral patterns between healthcare providers in the Nashville CBSA using the Hop Teaming dataset. The goal is to explore how primary care physicians (PCPs) refer patients to hospitals, understand referral communities, and create an interactive dashboard to visualize your insights.  

You will work with a PostgreSQL database containing the data you need. Additionally, you will use Neo4j to explore provider networks and apply community detection algorithms, and R Shiny to build an interactive visualization of referral patterns.

---

## Datasets Provided
The data for this project can be downloaded as a postgres backup from https://drive.google.com/file/d/1AqwuVf2DM7a-w8VM9wIX_p4nzOEUbQLM/view?usp=drive_link

**PostgreSQL Database:** Contains four main tables:  
   - `hop_team`:  Referral transactions between providers
   - `nppes`: Provider metadata
   - `nucc`: Taxonomy grouping, classification, and specialization
   - `zip_cbsa`: Zip Code/CBSA crosswalk

---

## Project Focus
To narrow the scope of the analysis, apply the following filters:
- For each provider, identify their primary taxonomy code. In the NPPES data, this is the taxonomy code whose corresponding taxonomy switch column is marked with 'Y'.
- For the referring providers, filter to Primary Care Physicians (PCPs) only: You can look for classifications of "Family Medicine", "Internal Medicine", "Pediatrics", and "General Practice"
- For the receiving providers, filter to hospitals.
- Only referrals in the Nashville CBSA.  
- To avoid incidental or low-volume referrals, look for significant referral relationships, meaning `transaction_count >= 50` and `avg_day_wait < 50`.

---

## Tasks

### 1. Create an Analytical Dataset
Create a materialized view that joins the necessary tables and applies the project filters:
- Primary taxonomy for each provider
- PCP specialties for referring providers
- Hospitals for receiving providers
- Nashville CBSA
- Significant referral relationships

This dataset will serve as the foundation for your SQL analysis, Neo4j network export, and Shiny dashboard.

### 2. SQL Analysis
Using PostgreSQL:  
- Identify PCPs who refer patients and the distribution of their referrals across major hospitals.  
- Find PCPs who refer few or no patients to Vanderbilt but send patients to competitor hospitals.  
- Aggregate by PCP specialty to understand which specialties are underrepresented in Vanderbilt’s referral network.

### 3. Neo4j Network Analysis
- Create a csv for the provider network in the Nashville CBSA.
- Load the provider network into Neo4j. In this network, providers are nodes and referral relationships are edges connecting them.   
- Apply the Louvain community detection algorithm to identify clusters of providers.  
- Explore which communities refer primarily to Vanderbilt vs competitors and highlight key PCP clusters.

### 4. R Shiny Dashboard
Build an interactive dashboard that allows users to:  
- Filter by PCP specialty, hospital, or CBSA.  
- Visualize top referring PCPs and their referral patterns.  
- Summarize competitor referral patterns and network clusters.  

### 5. Presentation
Prepare a brief presentation summarizing your findings:  
- Which PCP specialties or subgroups represent the largest potential growth opportunities for Vanderbilt.  
- Key insights from the referral network and community structure.  
- Recommendations for visualizations or dashboards that could support hospital decision-making.

---

## Deliverables
1. SQL queries used for analysis.  
2. Neo4j community detection output.
3. R Shiny dashboard with interactive filters and charts.  
4. Presentation summarizing key insights and observations.

---

## Learning Goals
- Practice SQL joins, aggregation, and filtering on real-world healthcare data.  
- Explore network analysis and community detection using Neo4j.  
- Create an interactive dashboard using R Shiny to communicate actionable insights.  
- Understand referral patterns and provider network dynamics in a real-world healthcare context.