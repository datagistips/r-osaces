setwd("D:/GITHUB_DATAGISTIPS/rosaces/rosaces")

library(spdep)
library(packcircles)
library(ggplot2)
library(rgdal)
library(rgeos)

source("fonctions.R")

## READ DATA ####
deps   <- readOGR("DATA/in/DEPARTEMENTS", "DEPARTEMENT")
popdep <- read.csv2("DATA/in/POP_DEP_2013/pop_dep_aq.csv", sep=",")

## MERGE with DATA ####
depsPop <- merge(deps, popdep, by.x="INSEE_DEP", by.y="CODE_DEPT")
depsPop <- depsPop@data[, 6:25]

## COMPUTE RADAR HEADS ####

## In case of custom parameters for rendering
# popParDep = apply(popdf, 1, mean)
# meanPop <- mean(popParDep)
# mult <- meanArea/meanPop

## Generic parameters for mult (control on QGIS if ok)
res <- radars(deps, popdf, fact=.7, mult=.9, exponent=2, minFactor=1/6, libelles=deps$NOM_DEP)

## PLOT ####
plot(deps)
plot(res$cercles, add=T)
plot(res$rosaces, add=T)

## SAVE ####
writeOGR(res$rosaces, "data/out", "rosaces", "ESRI Shapefile", overwrite=T)
writeOGR(res$cercles, "data/out", "cercles", "ESRI Shapefile", overwrite=T)
