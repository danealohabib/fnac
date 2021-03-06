## Code Supporting 'An Exploration of First Nations Reserves and Access to Cash'

Title of Publication: [An Exploration of First Nations Reserves and Access to Cash](https://www.bankofcanada.ca/2021/05/staff-discussion-paper-2021-8/)  
Paper Number: Paper 2021-8  
[MEDR](https://github.com/danealohabib/fnac/blob/main/First%20Nations%20-%20MEDR.docx)

### DESCRIPTION OF CODE
1. [data_process_1.R](https://github.com/danealohabib/fnac/blob/main/data_process_1.R)
 * Generates population data for all CSDs in Canada. Also defines which CSDs are associated with a reserve. 
2. [data_process_2.R](https://github.com/danealohabib/fnac/blob/main/data_process_2.R)
 * Data cleaning on the raw Mastercard data
 * We differentiated between WL ATMs and FI owned ATMs. Processing lat/lon variables for subsequent spatial data analysis
 * Web scrape/geocode missing Arctic Store ATMs    
3. [data_process_3.R](https://github.com/danealohabib/fnac/blob/main/data_process_3.R)
 * Web scraping/geocoding NW store locations
4. [data_process_4.R](https://github.com/danealohabib/fnac/blob/main/data_process_4.R)
 * Flag nearest cash source for each band office. 
 * Compute geo-distance and travel distance for each band office location
 * Flag ferry routes 
5. [data_process_5.R](https://github.com/danealohabib/fnac/blob/main/data_process_5.R)
 * Finding the nearest population center and compute distance to nearest population
 * Spatial join band office locations with CSDs boundary files
6. [output_1.R](https://github.com/danealohabib/fnac/blob/main/output_1.R)
 * Generate tables
7. [output_2.R](https://github.com/danealohabib/fnac/blob/main/output_2.R)
 * Generate figures
8. [master_output.R](https://github.com/danealohabib/fnac/blob/main/master_output.R)
 * Used to generate all table and figures
9. [master_process.R](https://github.com/danealohabib/fnac/blob/main/master_process.R)
 * Used to process all raw data
### REPLICATE ENTIRE ANALYSIS 

1. [Download band office data](https://open.canada.ca/data/en/dataset/b6567c5c-8339-4055-99fa-63f92114d9e4)

Indigenous and Northern Affairs Canada. 2019. First Nations Locations

2. [Download Census Subdivision boundry files](https://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/bound-limit-2016-eng.cfm)

Census Subdivision, 2016 Census. Statistics Canada Catalogue no. 92-160-X

3. [Download Population Centre Boundry files](https://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/bound-limit-2016-eng.cfm)

Statistics Canada. Population Centre Boundary File, 2016 Census. Statistics Canada Catalogue no 92-166-X

4. Retreive 2018 Mastercard ATM data from the Bank of Canada
 
Data available upon request  
Email: [DO'Habib@bank-banque-canada.ca](DO'Habib@bank-banque-canada.ca)

5. Retreive 2018 FIF database

Data can be found [here](https://www.payments.ca/our-directories/financial-institutions-branch-directory)  

Processed data available upon request.  

6. [Download census profiles for all CSDs](https://www12.statcan.gc.ca/census-recensement/2016/dp-pd/prof/details/page_Download-Telecharger.cfm?Lang=E&Tab=1&Geo1=CSD&Code1=59&Geo2=PR&Code2=01&SearchText=&SearchType=Begins&SearchPR=01&B1=All&TABID=1&type=0)

Data contains demographics for all CSDs within each province. Download data by province

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
