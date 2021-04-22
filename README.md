## Data and Code Supporting 'An Exploration of First Nations Reserves and Access to Cash'

Title of Publication: An Exploration of First Nations Reserves and Access to Cash
Paper Number: [To be completed by K&IS upon publication]
DOI of publication: [To be completed by K&IS upon publication]

### GENERATE TABLES AND FIGURES FROM PROCESSED DATA

1. Open the FNAC.Rproj to set global file path
2. Run master_output.R

### REPLICATE ENTIRE ANALYSIS 


Note: save all downloaded data in data/unprocessed/....

1. Download band office data:

** Download the data in shp format (data cleaning code won't work on the csv version) **
Indigenous and Northern Affairs Canada. 2019. First Nations Locations. Retrieved from https://open.canada.ca/data/en/dataset/b6567c5c-8339-4055-99fa-63f92114d9e4. 

2. Download Census Subdivision boundry files

Census Subdivision, 2016 Census. Statistics Canada Catalogue no. 92-160-X
https://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/bound-limit-2016-eng.cfm

3. Download Population Centre Boundry files

Statistics Canada. Population Centre Boundary File, 2016 Census. Statistics Canada Catalogue no 92-166-X
https://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/bound-limit-2016-eng.cfm

4. Retreive 2018 Mastercard ATM data from the Bank of Canada
 
Data and Information Resources A to Z: mastercard (bank-banque-canada.ca)
Contract of Mastercard ATM location data is managed by Alison Layng (CS).

5. Retreive 2018 FIF database

Data can be found here:https://www.payments.ca/our-directories/financial-institutions-branch-directory
For more information on data cleaning rules see appendix F of Chen, H. and M. Strathearn. 2020. “A Spatial Model of Bank Branches in Canada.” Bank of Canada Staff Working Paper 2020-4
Financial Institutions File from Payment Canada: fif@payments.ca

6. Download census profiles for all CSDs. 

Data contains demographics for all CSDs within each province
Click option 2 in link below
https://www12.statcan.gc.ca/census-recensement/2016/dp-pd/prof/details/page_Download-Telecharger.cfm?Lang=E&Tab=1&Geo1=CSD&Code1=59&Geo2=PR&Code2=01&SearchText=&SearchType=Begins&SearchPR=01&B1=All&TABID=1&type=0

Census Profile for Census Subdivisions in Alberta, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016069.

Census Profile for Census Subdivisions in British Columbia, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016070.

Census Profile for Census Subdivisions in Manitoba, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016067.

Census Profile for Census Subdivisions in New Brunswick, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016064.

Census Profile for Census Subdivisions in Newfoundland and Labrador, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016061.

Census Profile for Census Subdivisions in Nova Scotia, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016063.

Census Profile for Census Subdivisions in Nunavut, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016073.

Census Profile for Census Subdivisions in Northwest Territories, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016072.

Census Profile for Census Subdivisions in Ontario, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016066.

Census Profile for Census Subdivisions in Prince Edward Island, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016062.

Census Profile for Census Subdivisions in Quebec, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016065.

Census Profile for Census Subdivisions in Saskatchewan, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016068.

Census Profile for Census Subdivisions in Yukon, 2016 Census
Source: Statistics Canada, 2016 Census, Catalogue no. 98-401-X2016071.	

7. API KEY

Obtain free google maps API key
Save API key as txt files in api/...

8. Run script/master_process.R

This will generate the data used in data/processed folder
Note: data processing code takes about 15 mins to run on a ThinkPad X1 Yoga Gen 4
The next section outlines the data processing code.

9. Run output.R

tables and figures generated in output/
---------------------------------------------------------
DESCRIPTION OF CODE AND DATA
--------------------------------------------------------- 
script/data_process_1.R
-	Generates population data for all CSDs in Canada. Also defines which CSDs are associated with a reserve. 
script/data_process_2.R
-	Data cleaning on the raw Mastercard data. We differentiated between WL ATMs and FI owned ATMs. Processing lat/lon variables for subsequent spatial data analysis  
script/data_process_3.R
-	Web scraping/geocoding NW store locations
script/data_process_4.R
-	Flag nearest cash source for each band office. 
-	Compute geo-distance and travel distance for each band office location
-	Flag ferry routes 
script/data_process_5.R
-	Finding the nearest population center and compute distance to nearest population
-	Spatial join band office locations with CSDs boundary files
script/output_1.R
-	Generate tables
script/output_2.R
-	Generate figures
master_output.R
-	Used to generate all table and figures
script/master_process.R
-	Used to process all raw data
data/processed/band_reserve_count.csv
-	Used to identify the number of reserves belonging to each band
data/processed/band_summary_stats.csv
-	Used to generate summary stats for band offices and relevant CSDs
data/processed/distance_processed.csv
-	Distance measures for each band office location.
data/processed/ferry_routes.csv
-	Used to flag API trip with a ferry route 
