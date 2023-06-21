print('Er nå inne i ReadSQL_Tools.R')
#
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr) # For str_glue
#*#************* Slutt importere biblioteker

#*********** Start importere egen kildekode
#************** Foreløpig importere alle andre filer masterfilen
#************** Slutt importere egen kildekode
# Memo til selv: Har nå gått over til absolutt filsti siden working directory kan variere en del
#
get_sql_filename <- function(annual = FALSE,distinct = FALSE,pattern="\\.sql"){
  #Hjelpefunksjon for å plukke ut hvilken fil som inneholder sql-koden som
  # skal brukes.
  #
  typePattern <-  case_when(
    annual &  distinct ~ "year.*span",
    annual &   !distinct ~ "all.*annual",
    !annual &   distinct ~ "month.*span",
    !annual &   !distinct ~ "all.*month"
  )
  #    
  sql_file <- data.frame(
    last_part = list.files("."),
    fullName = list.files(".",full.names = TRUE)
    ) %>% 
    dplyr::filter(
      grepl(pattern = pattern, x= tolower(dplyr::pull(.,"last_part")),ignore.case = TRUE),
      grepl(pattern = typePattern, x= tolower(dplyr::pull(.,"last_part")),ignore.case = TRUE)
      ) %>%
    dplyr::pull(fullName)
  #
  return(sql_file)
}
#
get_sql_code <- function(single_line=TRUE,...){
  #
  sql_filename=get_sql_filename(...)
  #
  sql_code <- NULL
  if(is.character(sql_filename)){
    #Memo til selv: Siden koden hentes fra en SSMS -editor så er det vanskelig å få "UTF-8"- encoding.
    sql_code <- readLines(con=sql_filename,warn = FALSE,encoding = "Latin-1")
  }
  # Hvis ønskelig så slå sammen alle kodelinjene til en linje
  #
  if(all(single_line,!is.null(sql_code))){
    sql_code <- do.call(what="paste",args=as.list(sql_code))
  } 
  return(sql_code)
}
