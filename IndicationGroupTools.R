#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
#*#************* Slutt importere biblioteker
#

# Klasse for å lage ugrupperte figurer
#
setColors.IndicationGroup <- function(self){
  customBrewer <- customizeBrewer(self,"RdYlGn")
  custom_colors <- scale_color_manual(name = self$Grouping, values = customBrewer,drop=FALSE)
  return(custom_colors)
}
#
setTitle.IndicationGroup <- function(self){
  main_title <- "Totalt salg pr. indikasjonsgruppe"
  return(main_title)
}
#
createMonthlyPlot.IndicationGroup <- function(self){
  month_plot <- createGroupedMonthlyPlot(self)
  return(month_plot)
}
#
createAnnualPlot.IndicationGroup <- function(self){
  monthlyDDD <- createGroupedAnnualPlot(self)
  return(monthlyDDD)
}
