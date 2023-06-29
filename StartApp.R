#
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
#******* start shiny-biblioteker
library(shiny)
library(esquisse)
#******* sluttshiny-biblioteker
#*#************* Slutt importere biblioteker
#
#**************** Start import egenutviklet kode
source("DataExtractionTools.R",encoding = "UTF-8")
# For å lage plott
source("DDDplotTools.R",encoding = "UTF-8")
#*#**************** Slutt import egenutviklet kode 
#*********  Start app
runApp(appDir = ".")
