print('Er nå inne i SQL_Tools.R')
#
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr) # For str_glue
#******* Start biblioteker for SQL
library(odbc) #Lese fra SQL-databasen ved å kjøre SQL-script
library(RODBC) # Lese fra SQL-databasen
#******* Slutt biblioteker for SQL
#*#************* Slutt importere biblioteker
#### SQL -----

get_conn_str <- function(){
  # Veldig enkel hjelpefunksjon
  conn_str = 'driver={SQL Server};server=sql-grossist;database=Grossist_DWH;trusted_connection=true;'
  return(conn_str)
}
#
# Not to be confused with getConnection
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





