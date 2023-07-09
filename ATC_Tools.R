print('Er naa inne i ATC_Tools.R')
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
#
setTitle.ATC3 <- function(self){
  main_title <- "Totalt salg pr. ATC3-gruppe"
  return(main_title)
}
#
setColors.ATC3 <- function(self){
  customBrewer <- customizeBrewer(self,"Spectral")
  return(customBrewer)
}
#
setYlab.ATC3 <- function(self){
  ylab <- genericYlab()
  return(ylab)
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
