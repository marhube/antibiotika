#******** Start importere biblioteker
library(shiny)
library(tidyverse)
#******** Slutt importere biblioteker
#**************** Start import egenutviklet kode
#
# Memo til selv: Henter nå aller først inn alt vi trenger av data for alle varianter av brukerinput
#
# Se på https://stackoverflow.com/questions/52436755/adjusting-location-of-main-panel-in-shiny  for å plassere main panel (figuren)
# høyere opp
    fluidPage(
      # Header or Title Panel
      #Mer info om å sette inn bilde/logo https://community.rstudio.com/t/insert-an-image-in-the-title-on-shiny/97262/2
      titlePanel(title = span(img(src = "FHI_Logo.PNG", height = 35,align = "center"), "Antibiotikabarometer")),
      #
      # Sidebar panel
      sidebarLayout(
        sidebarPanel(
          selectInput("Grouping","1. Velg gruppeinndeling",choices = Groupings,selected = Groupings[1]),
          #
          radioButtons("tidsoppdeling", label = "Velg tidsoppdeling",
                   choices = c("månedlig", "årlig"), selected = "månedlig"),
          #
          selectizeInput("startYear","Velg startår",choices = NULL),
          selectizeInput("endYear","Velg sluttår",choices = NULL),
          #
          # Nyttig info fra https://shiny.posit.co/r/reference/shiny/1.4.0/conditionalpanel
          # Bare hvis dette panelet hvis tidsoppdeling er "månedlig"
          #Memo til selv: Default for "selected" er første verdi, så er unødvendig å sette den eksplisitt.
          # Vet heller ikke hvordan man kan definere hjelpevariabler, så bed å la være å sette"selected" eksplisitt
          # så trenger man heller ikke å hente inn data på nytt
          #Memo til selv: En viktig forkjell på startår for månedsdata og startår for "annual" (årlige) data er at for årlige data
          # så tas det kun med år der det er data tilgjengelig fra årets begynnelse (januar). Det er derfor "startår" er inni en "conditionalPanel
          conditionalPanel(
            condition = "input.tidsoppdeling == 'månedlig'",
            #
            selectizeInput("startMonth", "Velg startmåned",choices = NULL),
            #
            selectizeInput("endMonth","Velg sluttmåned",choices = NULL),
            #
            radioButtons("graphTypeMonthly",label = "Stablede kolonner",choices = c("Ja","Nei"),
                         selected = "Nei"),
            # Nested conditionalPanel
            conditionalPanel(
              condition = str_glue("graphTypeMonthly == 'Nei'"),
              radioButtons("run_avg", label = "Inkludér 12. mnd gjennomsnitt",
                     choices = c("Ja", "Nei"), selected = "Ja")
            )
          ),
          # Gjør nå "nested conditional panel
          # Memo til selv: Mer info: https://stackoverflow.com/questions/49960819/nested-conditional-panels-in-shiny-r
          #Nyttig info https://community.rstudio.com/t/selecting-inputs-that-is-filtered-based-on-previous-selectinput-values/134170 
          # og https://shiny.posit.co/r/reference/shiny/1.0.4/updatecheckboxinput
          #Memo til selv: Finne ut hvordan 
          conditionalPanel(
            condition = "input.tidsoppdeling == 'årlig' && input.Grouping != '{Groupings[1]}'",
              radioButtons("graphTypeAnnual",label = "Stablet eller side-ved-side",choices = c("stablet","side-ved-side"),
                          selected = "stablet")
          ),
          #
          #Memo til selv: "Totaltellingene har ingen undergrupper
          conditionalPanel(
            condition = str_glue("input.Grouping != '{Groupings[1]}'"),
            checkboxGroupInput("var","Velg variabler",choices = NULL)
          ),
          #
          # Input: Choose dataset ----
          selectInput("dataformat", "Velg format for nedlasting:",choices = c("csv", "excel")),
          # Button
          downloadButton("downloadData", "Download")
        # For betinget plotting: https://stackoverflow.com/questions/42474849/make-r-shiny-renderplot-reactive-to-text-input
      ),
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
  )
#