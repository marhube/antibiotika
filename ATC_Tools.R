print('Er naa inne i ATC_Tools17.R')
#
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
library(RColorBrewer) # For fargepaletter
#*#************* Slutt importere biblioteker
#
#**************** Start import egenutviklet kode
#*#**************** Slutt import egenutviklet kode 
# Klasse for å lage ugrupperte figurer
#Hjelpefunksjon for å sette farger
setColors.ATC3 <- function(self){
  customBrewer <- customizeBrewer(self,"Spectral")
  custom_colors <- scale_fill_manual(name = self$Grouping, values = customBrewer,drop=FALSE)
  return(custom_colors)
}
#
setTitle.ATC3 <- function(self){
  main_title <- "Totalt salg pr. ATC3-gruppe"
  return(main_title)
}
#
createMonthlyPlot.ATC3 <- function(self){
  month_plot <- createGroupedMonthlyPlot(self)
  return(month_plot)
}
#
createAnnualPlot.ATC3 <- function(self){
  monthlyDDD <- createGroupedAnnualPlot(self)
  return(monthlyDDD)
}
