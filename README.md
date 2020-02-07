# "Basic workflow for biodiversity data cleaning using R"

# 0. Loading packages

For this exercise, we will use the R environment. If you need to download it go to: https://www.r-project.org/. It is **strongly** suggested to use an editor and we recommend RStudio (https://rstudio.com).

For this tutorial, you will need to install the R packages: `rgbif`, `Taxonstand` `CoordinateCleaner` and `maps`. If you don't have them installed use the following commands:

```
install.packages("rgbif")
install.packages("Taxonstand")
install.packages("CoordinateCleaner")
install.packages("maps")
```

Then, we'll start loading the packages.  

```{r loading pkg}
library(rgbif)
library(Taxonstand)
library(CoordinateCleaner)
library(maps)
```

# 1. Getting the data

First, let's download the data of a tree species from South America *Cariniana legalis* from the Lecythidaceae family.

You can also embed plots, for example:

```{r occs}
species <- "Cariniana legalis"
occs <- occ_search(scientificName = species, 
                   return = "data")
nrow(occs) #number of records 
```

In the raw data, we have 500 records. 

Column names returned from gbif follow the DarwinCore standard (https://dwc.tdwg.org). 

```{r col-names}
colnames(occs)
```

## Exporting raw data

In order to guarantee the documentation of all steps, saving the raw data is essential. We will create a directory to save data and then export the data as csv (text file separated by comma).  

```{r save-raw}
dir.create("data")
write.csv(occs, 
          "data/raw_data.csv", 
          row.names = FALSE)
```

# 2. Checking species taxonomy

Let's check the unique entries for the species name we just searched.

```{r sp-name}
sort(unique(occs$scientificName))
```

In this particular case, we have two synonyms *Cariniana brasiliensis* and *Couratari legalis*. In the gbif data there is already a column showing the currently accepted taxonomy:

```{r sp-accepted}
table(occs$taxonomicStatus)
```

Let's use the function `TPL()` from package `taxonstand` to check if the taxonomic updates in the gbif data are correct. This function receives a vector containing a list of species and performs both ortographical and nomenclature checking. Nomenclature checking follows [The Plant List](http://www.theplantlist.org/). 

We will first generate a list with unique species names and combine it to the data. This is preferable because we do not need to check more than once the same name and, in the case of working with several species, it will make the workflow faster. 

```{r taxonstand}
species.names <- unique(occs$scientificName) 
tax.check <- TPL(species.names)
```

Let's check the output:

```{r tax-out}
tax.check
```

Note that the function adds several new variables to the input data and creates columns such as `New.Genus` and `New.Species` with the accepted name. We should adopt these names if the column `New.Taxonomic.status` is filled with "Accepted"

We will merge the new genus and species and then add them to the original data. 

```{r merge}
# creating new object w/ original and new names after TPL
new.tax <- data.frame(scientificName = species.names, 
                      genus.new.TPL = tax.check$New.Genus, 
                      species.new.TPL = tax.check$New.Species,
                      status.TPL = tax.check$Taxonomic.status,
                      scientificName.new.TPL = paste(tax.check$New.Genus,
                                                     tax.check$New.Species)) 
# now we are merging raw data and checked data
occs.new.tax <- merge(occs, new.tax, by = "scientificName")
```

## Exporting data after taxonomy check

To guarantee the documentation of all steps, we will export the data after the taxonomy check. 

```{r}
write.csv(occs.new.tax, 
          "data/data_taxonomy_check.csv", 
          row.names = FALSE)
```

# 3. Checking species' coordinates

First, let's inspect visually the coordinates in the raw data. 

```{r}
plot(decimalLatitude ~ decimalLongitude, data = occs)
map(, , , add = TRUE)
```

Now we will use the the function `clean_coordinates()` from the `CoordinateCleaner` package to clean the species records. This function checks for common errors in coordinates such as institutional coordinates, sea coordinates, outliers, zeros, centroids, etc. This function does not accept not available information (here addressed as "NA") so we will first select only data that have a numerical value for both latitude and longitude. 

Note: at this moment having a specific ID code for each observation is essential. The raw data already provides an ID in the column `gbifID`. 

```{r coord-prep}
occs.coord <- occs[!is.na(occs$decimalLatitude) 
                   & !is.na(occs$decimalLongitude),]
```

Now that we don't have NA in latitude or longitude, we can perform the coordinate cleaning.

```{r coord-clean}
# output w/ only potential correct coordinates
geo.clean <- clean_coordinates(x = occs.coord, 
                               lon = "decimalLongitude",
                               lat = "decimalLatitude",
                               species = "species", 
                               value = "clean")
```

Let's plot the output of the clean data. 

```{r map-plot}
par(mfrow = c(1, 2))
plot(decimalLatitude ~ decimalLongitude, data = occs)
map(, , , add = TRUE)
plot(decimalLatitude ~ decimalLongitude, data = geo.clean)
map(, , , add = TRUE)
par(mfrow = c(1, 1))
```

When setting `value = clean` it returns only the potentially correct coordinates. For checking and reproducibility we want to save all the output with the flags generated by the routine. Let's try a different output. 

```{r coord-clean-2}
occs.new.geo <- clean_coordinates(x = occs.coord, 
                                  lon = "decimalLongitude",
                                  lat = "decimalLatitude",
                                  species = "species", 
                                  value = "spatialvalid")
```
Then, we merge the raw data with the cleaned data.

```{r}
# merging w/ original data
occs.new.geo2 <- merge(occs, occs.new.geo, 
                       all.x = TRUE, 
                       by = "key") 
```


## Exporting the data after coordinate check

```{r}
write.csv(occs.new.geo2, 
          "../data/data_coordinate_check.csv", 
          row.names = FALSE)
```

Here is just of a quick example of a workflow of data cleaning using available tools in R.  
