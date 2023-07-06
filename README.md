# antibiotika
Overvåking av antibiotika


Breskrivelse filer:

startApp.R - > Kun for å sette igang kjøring  runApp
-- Appen kan startes inne i R (etter å ha satt working directory til mappen med filene)
--  ved kommandoen source("startApp.R") 


global.R Kjøres før resten av filene
--
DataExtractionTools.R Kalles på av global.R for å innhente data. Dette gjøres kun én gang
før selve webapplikasjonen kommer opp i nettleser. Alle plottene man kan gjøre i webapplikasjonen
bruker kun data fra dette første datauttrekket (SQL-spørringen med spørringer definert i
 AllAnnual.sql og AllMonthly.sql)


ui.R -- frontend
server.R -- backend

DDDplotTools.R "Hovedfil" for å lage plott. Får "litt hjelp" av 
"TotalTools.R", "ATC_Tools.R",  "IndicationGroupTools.R" og "NarrowBroadTools.R"

/www.FHI_logo.png -- bildefil med FHI-logo.
