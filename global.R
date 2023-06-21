print('Er nå inne i global.R')

#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr) # For str_glue
library(shiny)
#*#************* Slutt importere biblioteker
# Memo til selv: Starter nå med å hente inn data før starter webapplikasjonen (for å begrense antall spørringer mot databasen)
before_all_data <- Sys.time()
allMonthlyData <- extract_all_data(annual = FALSE)
allAnnualData <- extract_all_data(annual = TRUE)
#save(allMonthlyData,file= "allMonthlyData.RDATA")
#save(allAnnualData,file= "allAnnualData.RDATA")
#load("allMonthlyData.RDATA")
#load("allAnnualData.RDATA")
after_all_data <- Sys.time()
#
defGroupingAlternatives <- function(){
  return(c("Total","ATC3","indikatorgruppe","bred_vs_smal"))
}
#
print('Retrieving all data took')
print(after_all_data - before_all_data)
#
Groupings <- tail(colnames(allMonthlyData),4)
# Plukker ut navnet på tellevariablen
CountVariable <-  colnames(allAnnualData) %>%
  .[grepl(pattern = "^DDD.*1000",x=.,ignore.case=TRUE)]
  
