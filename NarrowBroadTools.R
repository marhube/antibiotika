print('Er naa inne i NarrowBroadTools8.R')
#
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
#*#************* Slutt importere biblioteker
#
#**************** Start import egenutviklet kode
#*#**************** Slutt import egenutviklet kode 
# Klasse for å lage ugrupperte figurer
#
setColors.NarrowBroad <- function(self){
  customBrewer <- brewer.pal(length(levels(dplyr::pull(self$plotData,"groupFactor"))), "RdYlGn")
  custom_colors <- scale_colour_manual(name = self$Grouping, values = customBrewer,drop = FALSE)  
  return(custom_colors)
}  
#
setTitle.NarrowBroad <- function(self){
  main_title <- "Totalt salg bred_vs_smal"
  return(main_title)
}
#
createMonthlyPlot.NarrowBroad <- function(self){
  month_plot <- createGroupedMonthlyPlot(self)
  return(month_plot)
}
#
createAnnualPlot.NarrowBroad <- function(self){
  monthlyDDD <- createGroupedAnnualPlot(self)
  return(monthlyDDD)
}