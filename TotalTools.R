#************* Start importere biblioteker
library(tidyverse)
library(dplyr)
library(stringr)
#*#************* Slutt importere biblioteker
#
#**************** Start import egenutviklet kode
#*#**************** Slutt import egenutviklet kode 
# Klasse for å lage ugrupperte figurer

setTitle.Total<- function(self){
  main_title <- "NORGE; grossiststat J01, excl metenamin"
  return(main_title)
}
#
# Memo til selv: Total-tellinger skiller seg ut ved at det blir veldig liten forskjell på hvordan man lager kurveplott og arealplott
createMonthlyPlot.Total <- function(self){
  main_title <- setTitle(self)
  #
  month_plot <- ggplot(
    self$plotData,
    aes(x=firstMonthDay,y=DDD_1000innb_dogn))  +
    scale_x_date(
      date_labels = "%b-%Y",
      breaks =  seq(from = min(self$plotData$firstMonthDay),to = max(self$plotData$firstMonthDay), by = "6 months"),
    ) + 
    ggtitle(main_title) +  
    labs(x= element_blank(),y = "DDD/1000 innbyggere/døgn") + 
    theme(
      plot.title=element_text(hjust=0.5),
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
    ) +
    ylim(0,NA)
  #Memo til selv: Kun støtte for 12mdn gjennomsnitt hvis kurvene ikke er "stablede kolonner"
  if(self$curveType == "line"){
    month_plot <- month_plot + geom_line(col="#4271c4",linetype = "solid")
    if(self$runAverage){
      month_plot <- month_plot + geom_line(aes(y=smoothDDD),linetype="dotted")
    }
  }else{
    month_plot <- month_plot  +  geom_area(color = NA, alpha = .4) +
      geom_line(position = "stack", linewidth = .2)
  }
  return(month_plot)
}
#
# Memo til self: "Ugrupperte grafer/figurer" er kun for totaltellinger
createAnnualPlot.Total <- function(self){
  main_title <- setTitle(self)
  #
  annual_plot <- ggplot(self$plotData,aes(x=yearFactor,y=DDD_1000innb_dogn,fill = DDD_1000innb_dogn))  +
    geom_bar(stat="identity",position = self$position,color = "black")  +
    #Memo til selv: Nyttig info på https://biostats.w.uib.no/color-scale-for-continuous-variables/
    scale_fill_gradient2(
      low = "green",
      mid = "yellow",
      high = "red",
      midpoint = median(dplyr::pull(self$plotData,"DDD_1000innb_dogn")),
    ) +
    #
    ggtitle(main_title) +  
    labs(x= element_blank(),y = "DDD/1000 innbyggere/døgn") + 
    theme(
      plot.title=element_text(hjust=0.5),
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
      legend.title=element_blank()
    ) +
    ylim(0,NA)
  #
  return(annual_plot)
}
#