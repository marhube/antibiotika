print('Er naa inne i DataExtractionTools.R')
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr) # For str_glue
library(lubridate)
#

#**************  Foreløpig importere alle andre filer masterfilen
source("SQL_Tools.R",encoding = "UTF-8")
source("ReadSQL_Tools.R",encoding = "UTF-8")
source("ManipulateSQL.R",encoding = "UTF-8")
#*********** Slutt importere egen kildekode
#
execute_query <- function(query,...){
  # må modifisere med funksjon som argument s
  #slik at man kan programmatisk modi 
  #  
  if(length(query)>1){
    query <- collapse_sql(query)
  }
  print('Er naa inne i execute_query der substr(query,1,1000) er')
  print(substr(query,1,1000))
  #
  conn <- get_conn(signature="RODBC")
  query_data <- sqlQuery(conn,query,as.is=TRUE,...)
  close(conn)
  #
  return(query_data)
}
# Teknisk hjelpefunksjon for å kunne angi tidligst mulige startdatoer
extractDistinctPeriods <- function(annual = FALSE){
  startEndMonthQuery <- get_sql_code(single_line = FALSE,annual = annual,distinct = TRUE) %>%
    prepare_sql_code(single_statement=TRUE) 
  #
  #******* Sjekk at SQL-kode kjører
  conn <- get_conn(signature="RODBC")
  startEndMonth <- sqlQuery(conn,startEndMonthQuery,as.is=TRUE)
  close(conn)
  #
  return(startEndMonth)
}
extract_all_data <- function(annual =FALSE){
  DDD_Query <- get_sql_code(single_line = FALSE,annual = annual,distinct = FALSE) %>%
    prepare_sql_code(single_statement=TRUE)
  #
  #******* Sjekk at SQL-kode kjører
  #Memo til selv: Siden nå har "as.is" lik FALSE så må jeg nå jobbe litt med "Total"
  conn <- get_conn(signature="RODBC")
  all_data <- sqlQuery(conn,DDD_Query,as.is=FALSE,na.strings = c("")) %>%
    dplyr::mutate(Total = as.character(Total)) %>%
    dplyr::mutate(Total = ifelse(is.na(Total),"",Total))
  close(conn)
  #
  return(all_data)
}
#


