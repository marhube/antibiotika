#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
#*#************* Slutt importere biblioteker
#
#**************** Start import egenutviklet kode
#*#**************** Slutt import egenutviklet kode 
setTitle.NarrowBroad <- function(self){
  main_title <- "Totalt salg bred_vs_smal"
  return(main_title)
}
#
setYlab.NarrowBroad <- function(self){
  ylab <- genericYlab()
  return(ylab)
}
#
setColors.NarrowBroad <- function(self){
  customBrewer <- customizeBrewer(self,"RdYlGn")
  return(customBrewer)
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