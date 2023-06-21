print('Er nå inne i ManipulateSQL.R')
# Kode for å rense og modifisere sql-kode
#
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr) # For str_glue
#*#************* Slutt importere biblioteker

#*********** Start importere egen kildekode
#**************  Foreløpig importere alle andre filer masterfilen
#*********** Slutt importere egen kildekode
#*

split_sql_code <- function(sql_code){
  # Teknisk hjelpefunksjon for å "splitte opp" sql-koder i ulike "setninger"
  #(ulike "statements" som slutter med ";")
  
  # bare en linje
  sql_code <- sql_code %>%
    str_split(pattern=";") %>%
    unlist() %>%
    trimws() %>% # Fjern "whitespace" først og sist i hver "sql statement"
    subset(nchar(.)>0)
}

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