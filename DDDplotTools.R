print('Er naa inne i DDDplotTools.R')
#
#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
library(roll) # For roll_mean
library(rlang) # For rlang::sym()
#*#************* Slutt importere biblioteker
#
#**************** Start import egenutviklet kode
source("TotalTools.R",encoding = "UTF-8")
source("ATC_Tools.R",encoding = "UTF-8")
source("IndicationGroupTools.R",encoding = "UTF-8")
source("NarrowBroadTools.R",encoding = "UTF-8")
#*#**************** Slutt import egenutviklet kode 
# Hjelpefunksjon for 
classMapper <- function(df){
  df <- data.frame(uiName = tail(colnames(df),4)) %>%
    dplyr::mutate(
      className = dplyr::case_when(
        # 
        toupper(uiName) %in% c("TOTAL","ATC3") ~ uiName,
        grepl(pattern="^indi",x= dplyr::pull(.,"uiName"),ignore.case=TRUE) ~ "IndicationGroup",
        grepl(pattern="^bred",x= dplyr::pull(.,"uiName"),ignore.case=TRUE) ~ "NarrowBroad"
      )
  )
  #
  return(df)
}
#
getDistinctPeriods <- function(df,desc=TRUE){
  print('Er nå inne i getDistinctPeriods')
  distinctPeriods <-  df %>%
    dplyr::pull(1) %>%
    unique() %>%
    sort()
  # Tar siste periode først hvis ønskelig
  if(desc){
    distinctPeriods <- rev(distinctPeriods)
  }
  return(distinctPeriods)
}
# Foreløpig uttrekk av variabler
getAllLevels <- function(df,Grouping){
  print('Er nå inne i getAllLevels')
  allLevels <- dplyr::pull(df,Grouping) %>%
    unique() %>%
    sort()
  #
  return(allLevels)
}
# Hjelpefunksjon for å sette farger på plott
customizeBrewer <- function(plotObj,palette){
  variableRanks <- plotObj$levelRanks %>%
    dplyr::arrange(levelRank) %>%
    dplyr::mutate(color = brewer.pal(nrow(.), palette)) %>%
    dplyr::filter(dplyr::pull(.,1) %in% plotObj$variables)
  #
  customBrewer <- dplyr::pull(variableRanks,"color") %>%
    setNames(dplyr::pull(variableRanks,plotObj$Grouping))
  #
  return(customBrewer)
}

# Memo til selv: OBSSSSSS Har kun implementert 12 måneders glatting
# Funksjon for å hente inn månedsvise data
createMonthlyPlotData <- function(plotObj){
  startMonth <- plotObj$startMonth
  #
  plotStart <- startMonth
  # Må ha med er data for å få "glattet kurve fra starten av".
  #
  if(plotObj$runAverage){
    stopifnot(plotObj$smoothPeriod == 12)
    startMonth = startMonth-100
  }
  #
  # Trekker først ut kun relevant tidsperiode (inklusive det som trengs av data for å lage glidende gjennomnsnitt)
  # Filtrerer også bort evt variabler som ikke huket av

  #
  # Memo til selv: Hvis ønskelig legges det til en glidende gjennomsnitt.
  # I "roll_mean" så blir "width(bredde) lik peridoelengde + 1 (f.eks 13 måneder for 12 måneders gjennomsnitt)
  monthlyDDD <-  plotObj$UnfilteredSummations %>%
    dplyr::filter(dplyr::pull(.,1) >= startMonth,dplyr::pull(.,plotObj$Grouping) %in% plotObj$variables)
  #
  #Glidende 12 mnd gjennomsnitt
  if(plotObj$runAverage){
    monthlyDDD <-   monthlyDDD %>% 
      dplyr::group_by(!!sym(plotObj$Grouping)) %>%
      dplyr::mutate(smoothDDD = roll_mean(!!sym(CountVariable),width = plotObj$smoothPeriod + 1)) %>% 
      dplyr::ungroup() %>%
      dplyr::filter(dplyr::pull(.,1) >= plotStart)
  }
  # Hvis oppgitt sluttmåned så av
  if(!is.null(plotObj$endMonth) && !is.na(plotObj$endMonth)){
    monthlyDDD  <- monthlyDDD  %>% 
      dplyr::filter(dplyr::pull(.,1) <= plotObj$endMonth)
  }
  #
  #Memo til selv: Plukker ut "årsdelen" og "månedsdelen" av tidskolonnen (første kolonne) for å lage datoer
  monthlyDDD <- monthlyDDD  %>% 
    dplyr::mutate(
      firstMonthDay = make_date(
        year = floor(dplyr::pull(.,1)/100),
        month = dplyr::pull(.,1) %%100, # %% gir modulus
        day = 1
      ),
      groupFactor = factor(dplyr::pull(.,plotObj$Grouping)),
    ) %>%
    #
    dplyr::mutate(
      groupFactor = fct_reorder(
        groupFactor,
        .x=dplyr::pull(.,CountVariable),
        .fun = median,
        .desc = TRUE
      )
    ) %>% 
    dplyr::arrange(!!sym(colnames(.)[1]),groupFactor)
  #
  return(monthlyDDD)
}
#
# Memo til selv:  Hvis det ikke er angitt noe sluttår så betyr det inntil siste kalenderår med data
createAnnualPlotData <- function(plotObj){
  # Fjerner data før "startYear" og etter "endYear"
  #Memo til selv: I "Anuual" trengs her ikke å filtrere på plotObj$Variables siden utgangspunktet her 
  # er den allerede filtrerte tabellen "Summations".
  annualDDD <- plotObj$Summations %>%
    dplyr::filter(dplyr::pull(.,1)>= plotObj$startYear)
  #
  if(!is.null(plotObj$endYear) && !is.na(plotObj$endYear)){
    print('Kommer inn i riktig if')
    print('dim(annualDDD) er først')
    print(dim(annualDDD))
    annualDDD <- annualDDD %>%
      dplyr::filter(dplyr::pull(.,1) <= plotObj$endYear)
    #
    print('dim(annualDDD) er deretter')
    print(dim(annualDDD))
  }
  #Memo til selv: CountVariable er definert i "global.R" (kanskje bedre å ha i funksjon)
  #Memo til selv: Har ikke
  annualDDD <- annualDDD %>% 
    dplyr::mutate(
      yearFactor = factor(dplyr::pull(.,1)),
      groupFactor = factor(dplyr::pull(.,plotObj$Grouping)),
      #
      firstDayOfYear = make_date(
        year = dplyr::pull(.,1),
        month = 1,
        day = 1
      )
    ) %>% # Memo til selv: Vil ha de største verdiene øverst. Bruker derfor "fct_reorder" til å sortere
    dplyr::mutate(
      groupFactor=fct_reorder(
        groupFactor,
        .x=dplyr::pull(.,CountVariable),
        .fun = median,
        .desc = TRUE
      )
    )
  #
  return(annualDDD)
}
#
createGroupedMonthlyPlot <- function(plotObj){
  # Henter først ut fargene
  customCols <- setColors(plotObj)
  main_title <- setTitle(plotObj)
  #
  # Memo til selv: https://stackoverflow.com/questions/22309285/how-to-use-a-variable-to-specify-column-name-in-ggplot
  month_plot <- ggplot( 
    plotObj$plotData,aes(x=firstMonthDay,y=!!rlang::sym(CountVariable),col=groupFactor))  +
    scale_x_date(
      date_labels = "%b-%Y",
      breaks =  seq(from = min(plotObj$plotData$firstMonthDay),to = max(plotObj$plotData$firstMonthDay), by = "6 months"),
    ) + 
    geom_line(linetype = "solid") + 
    customCols +
    geom_line(aes(y=smoothDDD),linetype="dotted") +
    ggtitle(main_title) +  
    labs(x= element_blank(),y = "DDD/1000 innbyggere/døgn") + 
    theme(
      plot.title=element_text(hjust=0.5),
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
    ) +
    ylim(0,NA) +
    labs(color =  plotObj$Grouping) 
  #  
  return(month_plot)
}
#
createGroupedAnnualPlot <- function(plotObj){
  customCols <- setColors(plotObj)
  main_title <- setTitle(plotObj)
  #
  print('Er nå inne i createGroupedAnnualPlot der plotObj$position er')
  print(plotObj$position)
  #
  annual_plot <- ggplot(plotObj$plotData,aes(x=yearFactor,y=DDD_1000innb_dogn,fill = groupFactor)) +
    geom_bar(stat="identity",col = "black",position=plotObj$position)  + 
    customCols  + 
    ggtitle(main_title) +  
    labs(x= element_blank(),y = "DDD/1000 innbyggere/døgn") + 
    theme(
      plot.title=element_text(hjust=0.5),
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
    ) + # Memo til selv: Setter "legend title "
    labs(fill =  plotObj$Grouping) +
    ylim(0,NA)
  #
  return(annual_plot)
}
#
createMonthlyPlot <- function(plotObj,...) UseMethod("createMonthlyPlot")
createAnnualPlot <- function(plotObj,...) UseMethod("createAnnualPlot")
setColors <- function(plotObj,...) UseMethod("setColors")
setTitle <- function(plotObj,...) UseMethod("setTitle")
#Memo til selv: CountVariable er definert i "global.R"
# Memo til selv:  For å sette riktige farger som ikke endrer seg selv om man varierer hvilke variabler man vil se på
# og for å kunne definere "glidende gjennomsnitt" så trengs summasjoner som ikke filtererer på starttid og sluttid 
# og heller ikke åp variabler så trengs en hjelpestabell med summasjoner som ikke er filtrert på verken tid eller variabler.
#
createUnfilteredSummations <- function(plotObj){
  # Memo til selv: Den første kolonnen formodes å inneholde tidsperiodene
  timeCol <- colnames(plotObj$allData)[1]
  # Lager hjelpestørrelser for å filtrere på tid
  summations <- plotObj$allData %>%
    dplyr::select(all_of(c(timeCol,CountVariable,plotObj$Grouping))) %>%
    dplyr::group_by(across(all_of(c(timeCol,plotObj$Grouping)))) %>%
    dplyr::summarize(across(all_of(CountVariable), ~  sum(.x))) %>% # Bør kanskje endre til å ha med option "na.rm = TRUE"
    dplyr::ungroup()
  #
  #
  return(summations)
}
#Hjelpefunksjon for å sette farger. Rangere

createSummations <- function(plotObj){
  # Memo til selv: Den første kolonnen formodes å inneholde tidsperiodene
  timeCol <- colnames(plotObj$allData)[1]
  # Lager hjelpestørrelser for å filtrere på tid
  firstPeriod <- plotObj$startMonth
  lastPeriod <- plotObj$endMonth
  #
  if(plotObj$annual){ 
    firstPeriod <- plotObj$startYear
    lastPeriod <- plotObj$endYear
  }
  #
  summations <- plotObj$UnfilteredSummations %>%
    dplyr::filter(dplyr::pull(.,1)>= firstPeriod,dplyr::pull(.,1)<= lastPeriod,
                  dplyr::pull(.,2) %in%  plotObj$variables
    )
  #
  return(summations)
}
#  Memo til selv: Hjelpefunksjon som rangerer hver "antibiotikakategori" etter "median av konsum" i historikken
createLevelRanks <- function(plotObj){
  # Skal her finne alle rangeringene  (med tanke på "CountVariable") til alle de ulike "levels"
  print('Er nå inne i getLevelRanks')
  print('head(plotObj$UnfilteredSummations) er')
  print(head(plotObj$UnfilteredSummations))
  # Gjør nå rangeringen kun på bakgrunn av tidsserien som brukes
  firstPeriod <- plotObj$startMonth
  lastPeriod <- plotObj$endMonth
  #
  if(plotObj$annual){ 
    firstPeriod <- plotObj$startYear
    lastPeriod <- plotObj$endYear
  }
  #
  levelRanks <- plotObj$UnfilteredSummations %>%
    dplyr::filter(dplyr::pull(.,1)>= firstPeriod,dplyr::pull(.,1)<= lastPeriod) %>%
    dplyr::group_by(!!sym(plotObj$Grouping)) %>%
    dplyr::summarize(across(all_of(CountVariable), ~ median(.x))) %>% 
    dplyr::ungroup() %>%
    dplyr::arrange(desc(!!sym(CountVariable))) %>%
    dplyr::mutate(levelRank = dplyr::row_number()) %>%
    dplyr::select(all_of(c(plotObj$Grouping,"levelRank")))
  #
  return(levelRanks)
}
#
createPlotData <- function(plotObj){
  data <- NULL
  if(plotObj$annual){
    data <- createAnnualPlotData(plotObj)
  }else{
    data <- createMonthlyPlotData(plotObj)
  }
  #
  return(data)
}
#
#Memo til selv: plotConstructur tar nå ansvar for de tingene som er felles for alle plottealternativene
# Memo til selv: Har nå bare én felles "constructor" for alle klassene
plotConstructor <- function(className,allData,variables = NULL,startMonth =NULL,endMonth = NULL,endYear = NULL,annual = FALSE,
                            runAverage = TRUE,smoothPeriod = 12,startYear = 2022,position = "stack"){
  #
  if(is.null(endMonth)){
    endMonth <- NA
  }
  #
  if(is.null(endYear)){
    endYear <- NA
  }
  #
  # Memo til selv: Må endre kolonnenavn til for at det ikke skal bli kluss med "className"
  #
  Grouping <-  classMapper(allData) %>% 
    dplyr::rename(mappingClass = className) %>%
    dplyr::filter(mappingClass == className) %>%
    dplyr::pull(uiName)
  #
  #Memo til selv: "position" kan alternativt være "dodged" (ved siden av hverandre)
  plotObj <- structure(
    list(allData = allData,
       Grouping = Grouping,
       variables = variables,
       annual = annual,
       runAverage = runAverage,
       startMonth = startMonth,
       endMonth = endMonth,
       smoothPeriod = 12,
       startYear = startYear,
       endYear = endYear,
       position = position
    ),
    class = className
  )
  #
  # Memo til selv:  For å sette riktige farger som ikke endrer seg selv om man varierer hvilke variabler man vil se på
  # og for å kunne definere "glidende gjennomsnitt" så trengs summasjoner som ikke filtererer på starttid og sluttid 
  # og heller ikke åp variabler så trengs en hjelpestabell med summasjoner som ikke er filtrert på verken tid eller variabler.
  plotObj$UnfilteredSummations <- createUnfilteredSummations(plotObj)
  # Lager så
  plotObj$levelRanks <- createLevelRanks(plotObj)  
  #
  plotObj$Summations <- createSummations(plotObj)
  plotObj$plotData <- createPlotData(plotObj)
  #
  if(annual){
    plotObj$gg2 <- createAnnualPlot(plotObj)
  }else{
    plotObj$gg2 <- createMonthlyPlot(plotObj)
  }
  # Memo til selv: Gjør så et rekursivt kall
  return(plotObj)
}