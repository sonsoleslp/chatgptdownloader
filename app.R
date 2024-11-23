library(shiny)
library(rio)
library(shinyWidgets)
library(DT)
library(shinyBS)
library(shinythemes)
library(chatgptscrapeR)
library(dplyr)
library(ggplot2)
library(ggiraph)
library(tidytext)
library(sentimentr)
library(wordcloud2)
library(networkD3)
source("ui.R")
source("helpers.R")

server <- function(input, output, session) {
  data <- reactiveVal(NULL)
  dataConvo <- reactiveVal(NULL)
  columns <- reactiveVal(NULL)
  convoColumns <- reactiveVal(NULL)
  urlColumn <- reactiveVal(NULL)
  warning_message <- reactiveVal(c())
  observeEvent(input$file, {
    tryCatch({
      df <- import(input$file$datapath)
      warning_message(c())
      data(df)
      columns(names(df))
      updateCheckboxGroupInput(session, "columnSelectors", choices = names(df), selected = names(df))
      
      conv <- df
      y <- which(conv[1,] |> as.matrix() |> checkUrl())
      col <- (columns())[ifelse(length(y) > 1, 1, y)]
      
      updateSelectInput(session, "urlSelect", choices = names(df), selected = col)
      
    }, error = function(e) {
      showNotification("Error loading data", type = "error")
    })
  })
  
  output$columnSelectors <- renderUI({
    req(columns())
    checkboxGroupInput("columnSelectors", "Select Columns to keep", choices = columns())
  })
  
  output$convoColumnSelectors <- renderUI({
    req(convoColumns())
    req(dataConvo())
    checkboxGroupInput("convoColumnSelectors", "Select Columns to keep", choices = names(dataConvo()), selected = convoColumns())
  })
  
  output$urlSelect <- renderUI({
    req(columns())
    selectInput("urlSelect", "Select ChatGPT column URLs", choices = columns())
  })
  
  output$dataView <- DT::renderDataTable({
    req(data())
    DT::datatable(data(), options = list(
      pageLength = 5, scrollX = TRUE
    ))
  })  
  output$dataViewConvo <- DT::renderDataTable({
    req(dataConvo())
    req(convoColumns())
    DT::datatable(dataConvo() |> select(all_of(convoColumns())),  options = list(
      pageLength = 5, scrollX = TRUE
    ))
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("data-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      toexport <- dataConvo() |> select(all_of(convoColumns()))
      list_columns <- sapply(toexport, is.list)
      
      # Replace NULL with NA in each list column
      for (col in names(toexport)[list_columns]) {
        toexport[[col]] <- lapply(toexport[[col]], 
                                  function(x) if (is.null(x)) NA else paste(x, collapse=" "))
      }
      
      rio::export(toexport, file, qmethod = "escape")
    }
  )
  
  observeEvent(input$nextButton, {
    warning_message()
    retrieveConversations(session, input, data, convoColumns, dataConvo, warning_message);
  })
  
  observeEvent(input$applyButton, {
    convoColumns(req(input$convoColumnSelectors)) 
  })
  
  observeEvent(input$select_all_button, {
    if (input$select_all_button %% 2 == 1) {
      updateCheckboxGroupInput(session, "convoColumnSelectors",
                               selected = names(dataConvo()))
    } else {
      updateCheckboxGroupInput(session, "convoColumnSelectors",
                               selected = NULL)
    }
  })  
  
  output$warning_note <- renderText({
    req(warning_message())
    if(length(warning_message()) > 0){
      paste(as.character(fansi::strip_sgr(warning_message())), collapse="")
    }
  })
  
  # Analytical Steps
  
  # Reactive data summary
  stats_summary <- reactive({
    chatgpt_data <- dataConvo()
    
    result <- list(
      n_conv = nrow(distinct(chatgpt_data, conversationId)),
      num_interactions = nrow(chatgpt_data),
      avg_response_length = chatgpt_data |>
        filter(message.author.role == "assistant") |>
        mutate(msg_length = nchar(message.content.parts)) |>
        dplyr::summarize(avg = mean(msg_length)) |> pull(avg),
      avg_interaction_length = chatgpt_data |>
        filter(message.author.role == "user" | message.author.role == "tool"  ) |>
        mutate(msg_length = nchar(message.content.parts)) |>
        dplyr::summarize(avg = mean(msg_length)) |> pull(avg)
    )
  })
  
  # Output for total interactions
  output$n_conv <- renderText({
    stats_summary()$n_conv
  })  
  
  # Output for total interactions
  output$num_interactions <- renderText({
    stats_summary()$num_interactions
  })
  
  # Output for average user input length
  output$avg_interaction_length <- renderText({
    round(stats_summary()$avg_interaction_length, 3)
  })
  
  # Output for average GPT response length
  output$avg_response_length <- renderText({
    round(stats_summary()$avg_response_length, 3)
  })
  
  
  output$plot1 <- renderGirafe({
    df <- dataConvo() |> 
      filter(message.author.role == "user" | message.author.role == "tool") |>
      mutate(msg_length = nchar(message.content.parts))
      
    p <- ggplot(df, aes(x = msg_length)) +
      geom_histogram_interactive(bins=30, aes(tooltip = after_stat(count),
                                              group = 1L), fill = "lightgray" ) +
      theme_minimal() + xlab("User message length")
    girafe(ggobj = p,  height_svg = 3)
  })
  
  output$plot2 <- renderGirafe({
    df <- dataConvo() |> 
      filter(message.author.role == "assistant") |>
      mutate(msg_length = nchar(message.content.parts))
    
    p <- ggplot(df, aes(x = msg_length)) +
      geom_histogram_interactive(bins=30, aes(tooltip = after_stat(count),
                                              group = 1L), fill = "lightgray" ) +
      theme_minimal() + xlab("ChatGPT message length") 
    girafe(ggobj = p,  height_svg = 3)
  })
  
  output$plot3 <- renderGirafe({
    df <- dataConvo() |> 
      group_by(conversationId) |> count()
    
    p <- ggplot(df, aes(x = n)) +
      geom_histogram_interactive(bins=30, aes(tooltip = after_stat(count),
                                              group = 1L), fill = "lightgray" ) +
      theme_minimal() + xlab("Number of messages")
    girafe(ggobj = p,  height_svg = 3)
  })
  
  
  
  output$wordcloudGPT <- renderWordcloud2({
    df <- dataConvo()
    req(df)
    text_data <- df |>
      filter(message.author.role == "assistant") |>
      unnest_tokens(word, message.content.parts, token = "words", to_lower = TRUE)
    
    text_data <- anti_join(text_data, get_stopwords(language = "en"))
    text_data <- count(text_data, word, sort = TRUE)
    wordcloud2(text_data, size = 1)
  })
  
  output$wordcloudUser <- renderWordcloud2({
    df <- dataConvo()
    req(df)
    text_data <- df |>
      filter((message.author.role == "user") | (message.author.role == "tool")) |>
      unnest_tokens(word, message.content.parts, token = "words", to_lower = TRUE)
    
    text_data <- anti_join(text_data, get_stopwords(language = "en"))
    text_data <- count(text_data, word, sort = TRUE)
    print(text_data)
    wordcloud2(text_data, size = 1, minSize = 1)
  })
  
  
}

shinyApp(ui, server)
