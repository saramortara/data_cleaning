# Tutorial for data cleaning

# loading packages

library(rgbif)

# basic search

species <- "Cariniana legalis"

occs <- occ_search(scientificName = species,
                   return = "data")

head(occs)
