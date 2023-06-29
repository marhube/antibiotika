print('Er naa inne i DataExtractionTools.R')
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr) # For str_glue
library(lubridate)
#******* Start biblioteker for SQL
library(odbc) #Lese fra SQL-databasen ved å kjøre SQL-script
library(RODBC) # Lese fra SQL-databasen
#****************
#*
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
#*
get_conn_str <- function(){
  # Veldig enkel hjelpefunksjon
  conn_str = 'driver={SQL Server};server=sql-grossist;database=Grossist_DWH;trusted_connection=true;'
  return(conn_str)
}
#
get_conn <- function(conn_str=get_conn_str(),signature="RODBC"){
  # Kan i denne funksjonen velge om man vil koble til vha funksjoner fra
  # RODBC-pakken eller odbc-pakken
  #
  conn <- NULL
  #
  if(signature=="RODBC"){
    conn <- RODBC::odbcDriverConnect(conn_str)
  }else if(signature=="odbc"){
    conn <- odbc::dbConnect(odbc(),.connection_string=conn_str)
  }
  return(conn)
}
#
#********** Start innhenting og manipulering av SQL-kode
#
prepare_sql_code <- function(sql_lines,single_statement=TRUE){
  #        
  no_comments_lines <- sql_lines %>%
    str_replace_all(pattern="--.*$",replacement = "") #Fjern eventuelle kommentarer
  #
  #slå først kodelinjene sammen til en linje, så splitt dem opp igjen 
  # med ";" som skilletegn
  no_comments_code <- do.call(what="paste",args=as.list(no_comments_lines))
  #
  if(!single_statement){
    no_comments_code <- split_sql_code(no_comments_code)
  }
  return(no_comments_code)
}
#
collapse_sql <- function(sql_code_statements,add_end=";"){
  # Enkel hjelpefunksjon som på mange måter gjør det motsatt ("reverserer)
  #funksjonen "split_sql_code" ved å slå sammen sql_kode fordelt på en vektor
  # av strenger med "statements" til en enkelt streng, der hver statement
  # er separert med "add_end"
  #
  sql_code <- do.call(
    what="paste",
    args=c(as.list(sql_code_statements),list(sep=add_end))) %>% 
    #må også legge til en semikolon helt på slutten
    paste0(";")
  #
  return(sql_code)
}
#
#********** Slutt innhenting og manipulering av SQL-kode
# ********** Start kjøre SQL-kode
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
#
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

# ********** Slutt kjøre SQL-kode


