/*
# Hop Teaming Analysis: Nashville Referral Network

## Overview
In this project, you will analyze referral patterns between healthcare providers in the Nashville CBSA using the Hop Teaming dataset. The goal is to explore how primary care physicians (PCPs) refer patients to hospitals, understand referral communities, and create an interactive dashboard to visualize your insights.  

You will work with a PostgreSQL database containing the data you need. Additionally, you will use Neo4j to explore provider networks and apply community detection algorithms, and R Shiny to build an interactive visualization of referral patterns.

## Project Focus
To narrow the scope of the analysis, apply the following filters:
(X) For each provider, identify their primary taxonomy code. In the NPPES data, this is the taxonomy code whose corresponding taxonomy switch column is marked with 'Y'.
(X) For the referring providers, filter to Primary Care Physicians (PCPs) only: You can look for classifications of "Family Medicine", "Internal Medicine", "Pediatrics", and "General Practice"
(X) For the receiving providers, filter to hospitals.
(x) Only referrals in the Nashville CBSA.  
(X) To avoid incidental or low-volume referrals, look for significant referral relationships, meaning `transaction_count >= 50` and `avg_day_wait < 50`.
*/ 

-- Create and update view: 
-- reduce number of transactions to significant referral relationships
DROP MATERIALIZED VIEW IF EXISTS HOP_LIMITED CASCADE;
 
CREATE MATERIALIZED VIEW HOP_LIMITED AS
SELECT
	*
FROM
	HOP_TEAM
WHERE
	TRANSACTION_COUNT >= 50
	AND AVERAGE_DAY_WAIT < 50;

-- Create and update view: 
-- Pull out primary taxonomy codes for npis in tennessee
DROP MATERIALIZED VIEW IF EXISTS nppes_taxonomy_filter CASCADE;

CREATE MATERIALIZED VIEW nppes_taxonomy_filter AS
			SELECT
				NPI,
				entity_type_code,
				organization_name,
				last_name,
				first_name,
				middle_name,
				name_prefix_text,
				name_suffix_text,
				credential_text,
				first_line_address,
				second_line_address,
				address_city_name,
				address_state_name,
				address_postal_code,
				CASE
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_1 IN ('Y', 'X') THEN HEALTHCARE_TAXONOMY_CODE_1
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_2 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_2
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_3 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_3
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_4 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_4
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_5 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_5
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_6 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_6
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_7 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_7
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_8 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_8
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_9 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_9
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_10 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_10
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_11 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_11
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_12 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_12
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_13 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_13
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_14 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_14
					WHEN HEALTHCARE_PRIMARY_TAXONOMY_SWITCH_15 = 'Y' THEN HEALTHCARE_TAXONOMY_CODE_15
					ELSE null
				END AS PRIMARY_TAXONOMY_CODE
			FROM
				NPPES
			WHERE address_state_name = 'TN'
;

-- Create and update view: 
-- from npi patients filtered by specific classifications
DROP MATERIALIZED VIEW IF EXISTS hop_limited_from_npi CASCADE;

CREATE MATERIALIZED VIEW hop_limited_from_npi AS
	SELECT
		*
	FROM
		nppes_taxonomy_filter AS PT
		INNER JOIN NUCC AS N ON PT.PRIMARY_TAXONOMY_CODE = N.CODE
		INNER JOIN hop_limited AS H ON H.FROM_NPI = PT.NPI
	WHERE
		N.CLASSIFICATION IN (
			'Family Medicine',
			'Internal Medicine',
			'Pediatrics',
			'General Practice'
);

-- Create and update view: 
-- referred npis for patients filtered by only hospitals
DROP MATERIALIZED VIEW IF EXISTS hop_limited_to_npi CASCADE;
		
CREATE MATERIALIZED VIEW hop_limited_to_npi AS
	SELECT
		*
	FROM
		nppes_taxonomy_filter AS PT
		INNER JOIN NUCC AS N ON PT.PRIMARY_TAXONOMY_CODE = N.CODE
		INNER JOIN hop_limited AS H ON H.TO_NPI = PT.NPI
	WHERE
	PT.entity_type_code = 2 AND N.grouping Ilike '%hospital%'
;

-- Create and update view: 
-- Final from npi dataset including nashville cbsa filter
DROP MATERIALIZED VIEW IF EXISTS nash_from_npi CASCADE;

CREATE MATERIALIZED VIEW nash_from_npi AS
WITH cbsa_nash_zip AS
(SELECT DISTINCT(zip)
FROM zip_cbsa
WHERE usps_zip_pref_state = 'TN' AND cbsa = '34980')
SELECT n.*,
code,
lf.grouping,
classification,
specialization,
definition,
notes,
display_name,
lf.section,
from_npi,
to_npi, 
patient_count,
transaction_count,
average_day_wait,
std_day_wait
FROM nppes_taxonomy_filter AS n
INNER JOIN cbsa_nash_zip AS c
ON c.zip = LEFT(n.address_postal_code,5)::NUMERIC
INNER JOIN hop_limited_from_npi AS lf
USING(npi);

SELECT * 
FROM
nash_from_npi;
-- Create and update view: 
-- Final to npi dataset including nashville cbsa filter
DROP MATERIALIZED VIEW IF EXISTS nash_to_npi CASCADE;

CREATE MATERIALIZED VIEW nash_to_npi AS
WITH cbsa_nash_zip AS
(SELECT DISTINCT(zip)
FROM zip_cbsa
WHERE usps_zip_pref_state = 'TN' AND cbsa = '34980')
SELECT n.*,
code,
lf.grouping,
classification,
specialization,
definition,
notes,
display_name,
lf.section,
from_npi,
to_npi, 
patient_count,
transaction_count,
average_day_wait,
std_day_wait
FROM nppes_taxonomy_filter AS n
INNER JOIN cbsa_nash_zip AS c
ON c.zip = LEFT(n.address_postal_code,5)::NUMERIC
INNER JOIN hop_limited_to_npi AS lf
USING(npi);

-- Create a view table with Hop patient transactions only for to-npi and from-npi of interest
-- one row = one patient transaction between both referring and receiving providers of interest 
DROP MATERIALIZED VIEW IF EXISTS HOP_LIMITED_CLEANED_PROVIDERS CASCADE;

CREATE MATERIALIZED VIEW HOP_LIMITED_CLEANED_PROVIDERS AS
WITH
	NASH_FROM_NPI_PROVIDERID AS (
		SELECT DISTINCT
			NPI
		FROM
			NASH_FROM_NPI
	),
	NASH_TO_NPI_PROVIDERID AS (
		SELECT DISTINCT
			NPI, classification 
		FROM
			NASH_TO_NPI
	)
SELECT
	HL.*, NT.classification as hospital_type
FROM
	HOP_LIMITED AS HL
	INNER JOIN NASH_FROM_NPI_PROVIDERID AS NN ON HL.FROM_NPI = NN.NPI
	INNER JOIN NASH_TO_NPI_PROVIDERID AS NT ON HL.TO_NPI = NT.NPI;

SELECT * 
FROM HOP_LIMITED_CLEANED_PROVIDERS;

-- Create a view table with ONLY receiving provider contact information
-- one row = one provider id with relevant info
DROP MATERIALIZED VIEW IF EXISTS hospital_receiving_provider_information CASCADE;

CREATE MATERIALIZED VIEW hospital_receiving_provider_information AS
WITH
	NASH_TO_NPI_PROVIDERID AS (
		SELECT DISTINCT
			NPI
		FROM
			NASH_TO_NPI)
SELECT * 
FROM nppes_taxonomy_filter as ntf
WHERE ntf.npi IN (SELECT * FROM NASH_TO_NPI_PROVIDERID);


-- Create a view table with ONLY referring provider contact information
-- one row = one reffering provider id with relevant info
DROP MATERIALIZED VIEW IF EXISTS referring_provider_information CASCADE;

CREATE MATERIALIZED VIEW referring_provider_information AS
WITH
	NASH_FROM_NPI_PROVIDERID AS (
		SELECT DISTINCT
			NPI, classification, grouping
		FROM
			NASH_FROM_NPI)
SELECT ntf.*,  nfp.classification, nfp.grouping
FROM nppes_taxonomy_filter as ntf
INNER JOIN NASH_FROM_NPI_PROVIDERID as nfp ON ntf.npi = nfp.npi;
________________
-- Identify PCPs who refer patients and the distribution of their referrals across major hospitals.
-- Find PCPs who refer few or no patients to Vanderbilt but send patients to competitor hospitals.

-- TABLE: All the PCPs who are NOT currently VUMC customer/systems (aka the 'gap in the market')
--- TABLE with PCPs filtered by vanderbilt 
/*
SELECT
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME,
	SUM(TR.PATIENT_COUNT) AS NUM_PATIENTS
FROM
	HOP_LIMITED_CLEANED_PROVIDERS AS TR
	INNER JOIN HOSPITAL_RECEIVING_PROVIDER_INFORMATION AS HP ON TR.TO_NPI = HP.NPI
WHERE
	HP.ORGANIZATION_NAME NOT ILIKE 'VANDERBILT%'
GROUP BY
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME
EXCEPT
SELECT
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME,
	SUM(TR.PATIENT_COUNT) AS NUM_PATIENTS
FROM
	HOP_LIMITED_CLEANED_PROVIDERS AS TR
	INNER JOIN HOSPITAL_RECEIVING_PROVIDER_INFORMATION AS HP ON TR.TO_NPI = HP.NPI
WHERE
	HP.ORGANIZATION_NAME ILIKE '%VANDER%'
GROUP BY
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME
HAVING
	SUM(TR.PATIENT_COUNT) >= 100
ORDER BY
	NUM_PATIENTS DESC;
*/ 

-- Aggregate by PCP specialty to understand which specialties are underrepresented in Vanderbilt’s referral network.
-- TABLE: All the PCPs who are NOT currently VUMC customer/systems (aka the 'gap in the market')
WITH pcp_not_vandy_network as (SELECT
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME, 
	rpi.classification,
	rpi.grouping, 
	SUM(TR.PATIENT_COUNT) AS NUM_PATIENTS
FROM
	HOP_LIMITED_CLEANED_PROVIDERS AS TR
	INNER JOIN HOSPITAL_RECEIVING_PROVIDER_INFORMATION AS HP ON TR.TO_NPI = HP.NPI
	INNER JOIN referring_provider_information AS rpi on TR.from_NPI = rpi.NPI
WHERE
	HP.ORGANIZATION_NAME NOT ILIKE 'VANDERBILT%'
GROUP BY
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME,
	rpi.classification, 
	rpi.grouping
EXCEPT
SELECT
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME, 
	rpi.classification,
	rpi.grouping,
	SUM(TR.PATIENT_COUNT) AS NUM_PATIENTS
FROM
	HOP_LIMITED_CLEANED_PROVIDERS AS TR
	INNER JOIN HOSPITAL_RECEIVING_PROVIDER_INFORMATION AS HP ON TR.TO_NPI = HP.NPI
	INNER JOIN referring_provider_information AS rpi on TR.from_NPI = rpi.NPI
WHERE
	HP.ORGANIZATION_NAME ILIKE '%VANDER%'
GROUP BY
	TR.FROM_NPI,
	HP.ORGANIZATION_NAME, 
	rpi.classification,
	rpi.grouping
HAVING
	SUM(TR.PATIENT_COUNT) >= 100
ORDER BY
	NUM_PATIENTS DESC)
SELECT SUM(NUM_PATIENTS), classification 
FROM pcp_not_vandy_network as rp
GROUP BY classification 
ORDER BY SUM(NUM_PATIENTS) DESC;


/* NOTES
* add in 'speciaties' column, needs to be added at the referring_provider_info materialized view
*/