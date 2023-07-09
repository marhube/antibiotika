#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
#*#************* Slutt importere biblioteker
#

# Klasse for å lage ugrupperte figurer
#
setTitle.IndicationGroup <- function(self){
  main_title <- "Totalt salg pr. indikasjonsgruppe"
  return(main_title)
}
#
setColors.IndicationGroup <- function(self){
  customBrewer <- customizeBrewer(self,"RdYlGn")
  return(customBrewer)
}
#
setYlab.IndicationGroup<- function(self){
  ylab <- genericYlab()
  return(ylab)
}

createMonthlyPlot.IndicationGroup <- function(self){
  month_plot <- createGroupedMonthlyPlot(self)
  return(month_plot)
}
#
createAnnualPlot.IndicationGroup <- function(self){
  monthlyDDD <- createGroupedAnnualPlot(self)
  return(monthlyDDD)
}
