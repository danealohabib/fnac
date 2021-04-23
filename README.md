## Data and Code Supporting 'An Exploration of First Nations Reserves and Access to Cash'

Title of Publication: An Exploration of First Nations Reserves and Access to Cash  
Paper Number: [To be completed by K&IS upon publication]  
DOI of publication: [To be completed by K&IS upon publication]

### GENERATE TABLES AND FIGURES FROM PROCESSED DATA

1. Create an R project
2. Run master_output.R

### DESCRIPTION OF CODE AND DATA
1. data_process_1.R
* Generates population data for all CSDs in Canada. Also defines which CSDs are associated with a reserve. 
2. data_process_2.R
* Data cleaning on the raw Mastercard data. We differentiated between WL ATMs and FI owned ATMs. Processing lat/lon variables for subsequent spatial data analysis  
3. data_process_3.R
* Web scraping/geocoding NW store locations
4. data_process_4.R
* Flag nearest cash source for each band office. 
* Compute geo-distance and travel distance for each band office location
* Flag ferry routes 
5. data_process_5.R
* Finding the nearest population center and compute distance to nearest population
* Spatial join band office locations with CSDs boundary files
6. output_1.R
* Generate tables
7. output_2.R
* Generate figures
8. master_output.R
* Used to generate all table and figures
9. master_process.R
* Used to process all raw data
### REPLICATE ENTIRE ANALYSIS 

1. Download band office data:

* Indigenous and Northern Affairs Canada. 2019. First Nations Locations. Retrieved from https://open.canada.ca/data/en/dataset/b6567c5c-8339-4055-99fa-63f92114d9e4. 

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

7. API KEY

Obtain free google maps API key

8. master_process.R

9. Run output.R

### R Packages

The pacman package is used to managed all R packages used in the analysis. Package list: 
data.table  
pacman  
gt  
rvest  
xml2  
googleway  
ggmap  
gmapsdistance  
here  
nngeo  
janitor  
sf  
tidyverse
