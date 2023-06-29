print('Er nå inne i global.R')

#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr) # For str_glue
library(purrr) # For partial function
#*#************* Slutt importere biblioteker
# Memo til selv: Starter nå med å hente inn data før starter webapplikasjonen (for å begrense antall spørringer mot databasen)
allMonthlyData <- extract_all_data(annual = FALSE)
allAnnualData <- extract_all_data(annual = TRUE)
#
Groupings <- tail(colnames(allMonthlyData),4)
# Plukker ut navnet på tellevariablen
CountVariable <-  colnames(allAnnualData) %>%
  .[grepl(pattern = "^DDD.*1000",x=.,ignore.case=TRUE)]
  
# Lager hjelpefunksjon for å trekke ut norske månedsnavn
monthNameFunc <- purrr::partial(lubridate::month,...=,label = TRUE,abbr=FALSE,locale="Norwegian_Norway")
#
