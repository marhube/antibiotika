#********** Start importere biblioteker
library(shiny) # Load shiny package
library(tidyverse)
library(stringr) # For str_glue()
library(purrr) # For partial function
library(openxlsx) # For å kunne eksportere data som excel-regneark
library(lubridate)

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
      paste("Graftype er", input$graphTypeAnnual)
    })
    # ******* reactive calculations
    # reaktivt uttrekk av variabelmuligheter
    # Først plukke ut mulige sluttmåneder og så mulige "sluttår"
    # ************* Start  Velger startår
    startYearOptions <- reactive({
      # For årlige tellinger kan man kun velge år der det finnes tellinger for alle månedene i året.  For månedlige tellinger 
      # kan startår og sluttår være år der finnes tellinger for bare noen av månedene.
      options <- getDistinctPeriods(allAnnualData,desc = TRUE)
      if(input$tidsoppdeling =="månedlig"){
        options <- unique(floor(getDistinctPeriods(allMonthlyData,desc = TRUE)/100))
      }
      options
    })
    #
    observe(input$tidsoppdeling) %>%
      bindEvent({
        updateSelectizeInput(session,"startYear", choices = startYearOptions())
    })
    # ************* Slutt  Velger startår
    # ************* Start  Velger startmåned (kun hvis månedlig telling)
    #Hvis startåret er det første året  i dataene så er ikke første mulige måned januar, men ellers er det januar
    startMonthOptions <- reactive({
      getDistinctPeriods(allMonthlyData,desc = FALSE) %>%
        .[floor(./100) == input$startYear] %>% 
        '%%'(100) %>%  # Trekker ut månedsdelen ved å gjøre modulus 100
        sort() %>%  # For å få månedene i stigende rekkefølge
        monthNameFunc()
    })
    #
    observe(input$startYear) %>%
      bindEvent({
        updateSelectizeInput(session,"startMonth", choices = startMonthOptions())
    })
    #
    # ************* Slutt  Velger startmåned (kun hvis månedlig telling)
    #**************** Start Velger sluttår
    endYearOptions <- reactive({
      # For årlige tellinger kan man kun velge år der det finnes tellinger for alle månedene i året.  For månedlige tellinger 
      # kan startår og sluttår være år der finnes tellinger for bare noen av månedene.
      options <- getDistinctPeriods(allAnnualData,desc = TRUE)
      if(input$tidsoppdeling =="månedlig"){
        options <- floor(getDistinctPeriods(allMonthlyData,desc = TRUE)/100)
      }
      options %>%
        .[.>= input$startYear]
    })
    #
    observe(input$startYear) %>%
      bindEvent({
        updateSelectizeInput(session,"endYear", choices = endYearOptions())
      })
    #
    #**************** Slutt Velger sluttår
    #**************** Start Velger sluttmåned
    endMonthOptions <- reactive({
      options <- getDistinctPeriods(allMonthlyData,desc = FALSE) %>%
        .[floor(./100) == input$endYear] %>%
        '%%'(100)
      if(input$endYear == input$startYear){
        startMonth <- which(monthNameFunc(1:12) == input$startMonth)
        options <- options[options >= startMonth]
      } # Vil for sluttmåneder ha siste måned først
      sort(options,decreasing = TRUE) %>%
        monthNameFunc()
    })
    # Memo til selv: Ligner på tidligere "observe event" i "gammel shiny"
    observe(input$startMonth) %>%
      bindEvent({
        updateSelectizeInput(session,"endMonth", choices = endMonthOptions())
      })
    #
    #**************** Slutt Velger sluttmåned
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
          position = if(input$graphTypeAnnual == "stablet") "stack" else "dodge"
          )
      }else{
        constructor <- purrr::partial(
          .f=constructor,
          allData = allMonthlyData,
          annual = FALSE,
          startMonth = (100 * as.integer(input$startYear)) +  which(monthNameFunc(1:12) == input$startMonth),
          endMonth = (100 * as.integer(input$endYear)) + which(monthNameFunc(1:12) == input$endMonth),
          curveType = if(input$graphTypeMonthly == "Ja") "area" else "line"
        )
        # Memo til selv: Har kun implementert støtet for 12 mnd gjennomsnitt hvis kurvene ikke er "stablede kolonner"
        if(input$graphTypeMonthly == "Nei"){
          constructor <- purrr::partial(
            .f=constructor,
            runAverage = (input$run_avg  == "Ja")
          )
        }else{
          constructor <- purrr::partial(
            .f=constructor,
            runAverage =  FALSE
          )
        }
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
        # Trekker ut startmåned og sluttmåned fra dataene som er behandlet
        firstPeriod <- plotObj$startMonth
        lastPeriod <- plotObj$endMonth
        #
        if(plotObj$annual){ 
          firstPeriod <- plotObj$startYear
          lastPeriod <- plotObj$endYear
        }
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

