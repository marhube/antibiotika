#********** Start importere biblioteker
library(shiny) # Load shiny package
library(tidyverse)
library(stringr) # For str_glue()
library(purrr) # For partial function
library(esquisse) # For safe_ggplot
library(openxlsx) # For å kunne eksportere data som excel-regneark

#********** Slutt importere biblioteker
# Memo til selv: Egen kode hentes nå før det gjøre kall på appen
server <-   function(input, output,session){
    output$text1 <- renderText({ 
      colm = input$Grouping
      paste("Valgt gruppeinndeling er", colm)
    })
    output$text2 <- renderText({ 
      paste("Tidsinndeling er", input$tidsoppdeling)
    })
    # #----
    #Memo til selv: Kaller nå på en hjelpefunksjon for å gå fra brukerinput til klassenavnet i koden
    # Har nå også lagt til logikk for skille mellom månedlige og årlige plott
    #
    output$text3 <- renderText({ 
      paste("Graftype er", input$graphType)
    })
    # ******* reactivet calcualtions
    # reaktivt uttrekk av variabelmuligheter
    # Først plukke ut mulige sluttmåneder og så mulige "sluttår"
    endMonthOptions <- reactive({
      getDistinctPeriods(allMonthlyData,desc = TRUE) %>%
        .[.>=input$startMonth]
    })
    # Memo til selv: Ligner på tidligere "observe event" i "gammel shiny"
    observe(input$startMonth) %>%
      bindEvent({
        updateSelectizeInput(session,"endMonth", choices = endMonthOptions())
      })
    #
    endYearOptions <- reactive({
      getDistinctPeriods(allAnnualData,desc = TRUE) %>%
        .[.>=input$startYear]
    })
    #
    observe(input$startYear) %>%
      bindEvent({
        updateSelectizeInput(session,"endYear", choices = endYearOptions())
      })
    # Memo til selv: "AnnualData" og "MonthlyData" har samme "levels". Velger "AnnualData" 
    # sind det er den minste tabellen
    variableOptions <- reactive({
      getAllLevels(allAnnualData,Grouping = input$Grouping)
    })
    # Memo til selv: Checkboxes kan velges uavhengig av hverandre
    observe(input$Grouping) %>%
      bindEvent({
        updateCheckboxGroupInput(
          session,"var", 
          choices = variableOptions(),
          selected = variableOptions()
        )
      })
    #
    #Nyttig info
    # http://127.0.0.1:19386/library/shiny/html/bindEvent.html
    #constructor <- purrr::partial(.f=plo#tConstructor,classMapper(input$var),annual = annual,...=)
    generatePlotObject <- reactive({
    #
      className <- dplyr::filter(classMapper(allAnnualData),uiName ==input$Grouping) %>%
        dplyr::pull(className)
      # Mer info om "caching" fra http://127.0.0.1:10288/library/shiny/html/bindCache.html
      # Gjør bare ny beregning hvis "updateButton" er trykket på
      constructor <- purrr::partial(.f=plotConstructor,className,variables = input$var,...=)
      if(toupper(input$tidsoppdeling) == "ÅRLIG"){
        constructor <- purrr::partial(
          .f=constructor,
          allData =  allAnnualData,
          annual = TRUE,
          startYear = as.integer(input$startYear),
          endYear = as.integer(input$endYear),
          position = if(input$graphType == "stablet") "stack" else "dodge"  
          )
      }else{
        constructor <- purrr::partial(
          .f=constructor,
          allData = allMonthlyData,
          annual = FALSE,
          startMonth = as.integer(input$startMonth),
          endMonth = as.integer(input$endMonth)
        )
      } # Returnerer objektet ikke funksjonen
      constructor()
    })  %>%
      bindCache(input$updateButton)
    # Kode som sørger for at figuren kun oppdateres når brukeren ber om det
    # Take a dependency on input$updateButton. This will run once initially,
    # because the value changes from NULL to 0.
    #
    output$antibioticGraph <- renderPlot(
      {
      plotObject <- generatePlotObject()
      show(plotObject$gg2)
      },
      height = 400,
      width = 700
    ) |> #Memo til selv: Info om om |> syntaks: https://stackoverflow.com/questions/67744604/what-does-pipe-greater-than-mean-in-r
      bindEvent(input$updateButton)
    #
    # Mer info om å eksportere data i shiny via "download button
    # https://shiny.posit.co/r/articles/build/download/
    
    # Reactive value for selected dataset ----
    #
    output$downloadData <- downloadHandler(
      filename = function() {
        # Hvis brukeren ønsker en excel-fil så vil filnavnet slutte på "xlsx"
        fileExtension <-  if(input$dataformat == "excel") "xlsx" else "csv"
        str_glue('{input$Grouping}.{fileExtension}')
      },
      #
      content = function(file){    
        plotObj <- generatePlotObject()
        #
        #Filtrerer først på hvilke variabler som brukeren er interessert i
        data <- plotObj$Summations %>%
          dplyr::filter(dplyr::pull(.,2) %in% plotObj$variables) %>%
          dplyr::filter(dplyr::pull(.,1)>= firstPeriod,dplyr::pull(.,1)<= lastPeriod)
        #
        # Skrivefunksjonen blir forskjellig avhengig av om brukeren vil ha data på excelformat
        # eller csv-format
        writer <- NULL
        #
        if(input$dataformat =="excel"){
          writer =  purrr::partial(.f= write.xlsx,x = data,file = file,...=)
        }else{
          writer =  purrr::partial(.f= write.csv,data,file,row.names = FALSE,...=)
        }
        # 
        writer()
      }
    )
  }

