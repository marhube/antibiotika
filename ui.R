#******** Start importere biblioteker
library(shiny)
library(tidyverse)
#******** Slutt importere biblioteker
#**************** Start import egenutviklet kode
# Memo til selv: Egen kode hentes nå før det gjøre kall på appen
#source("./Shiny/MultipleSelectionTools/MultipleSelectionTools_file.R",encoding = "UTF-8")
#*#**************** Slutt import egenutviklet kode 

# Define UI for application
# choices <- seq_along(defGroupingAlternatives()) %>% 
#   setNames(defGroupingAlternatives())
#
# Memo til selv: Henter nå aller først inn alt vi trenger av data for alle varianter av brukerinput
#
    fluidPage(
      # Header or Title Panel
      titlePanel(title = h4("Velg inndeling",align = "center")),
      #
      # Sidebar panel
      sidebarPanel(
      selectInput("Grouping","1. Velg gruppeinndeling",choices = Groupings,
                  selected = Groupings[1]),
      #
      radioButtons("tidsoppdeling", label = "Velg tidsoppdeling",
                   choices = c("månedlig", "årlig"), selected = "månedlig")
      ),
      # Nyttig info fra https://shiny.posit.co/r/reference/shiny/1.4.0/conditionalpanel
      # Bare hvis dette panelet hvis tidsoppdeling er "månedlig"
      #Memo til selv: Default for "selected" er første verdi, så er unødvendig å sette den eksplisitt.
      # Vet heller ikke hvordan man kan definere hjelpevariabler, så bed å la være å sette"selected" eksplisitt
      # så trenger man heller ikke å hente inn data på nytt
      conditionalPanel(
        condition = "input.tidsoppdeling == 'månedlig'",
        selectizeInput("startMonth", "Velg startmåned",
                       choices = getDistinctPeriods(allMonthlyData,desc = TRUE),
                       selected = getDistinctPeriods(allMonthlyData,desc = TRUE)[1],
                       options = list(maxOptions = 12)
                       ),
        #
        selectizeInput("endMonth","Velg sluttmåned",choices = NULL)
      ),
      # Gjør nå "nested conditional panel
      # Memo til selv: Mer info: https://stackoverflow.com/questions/49960819/nested-conditional-panels-in-shiny-r
      #Nyttig info https://community.rstudio.com/t/selecting-inputs-that-is-filtered-based-on-previous-selectinput-values/134170 
      # og https://shiny.posit.co/r/reference/shiny/1.0.4/updatecheckboxinput
      conditionalPanel(
        condition = "input.tidsoppdeling == 'årlig'",
        selectizeInput("startYear", "Velg startår",
                       choices = getDistinctPeriods(allAnnualData,desc=TRUE),
                       selected = getDistinctPeriods(allAnnualData,desc = TRUE)[1],
                       options = list(maxOptions = 10)
                    ),
        selectizeInput("endYear","Velg sluttår",choices = NULL),
        # Nested conditionalPanel
        conditionalPanel(
          condition = str_glue("input.Grouping != '{Groupings[1]}'"),
          selectInput("graphType", "Stablet eller side-ved-side",choices = c("stablet","side-ved-side"),
                      selected = "stablet")
        )
      ),
      #Memo til selv: "Totaltellingene har ingen undergrupper
      conditionalPanel(
        condition = str_glue("input.Grouping != '{Groupings[1]}'"),
        checkboxGroupInput(
          "var",
          "Velg variabler",
          choices = NULL,
        ),
      ),
      #
      sidebarPanel(
        # Input: Choose dataset ----
        selectInput("dataformat", "Velg format for nedlasting:",
                    choices = c("csv", "excel")),
        # Button
        downloadButton("downloadData", "Download")
      ),
      # For betinget plotting: https://stackoverflow.com/questions/42474849/make-r-shiny-renderplot-reactive-to-text-input
      # Main Panel
      mainPanel(
        textOutput("text1"),
        textOutput("text2"),
        textOutput("text3"),
        textOutput("text4"),
        actionButton("updateButton", "Oppdater figur", class = "btn-update"),
        plotOutput("antibioticGraph")
      )
    )
#