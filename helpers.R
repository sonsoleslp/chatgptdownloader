scrape <- function(x, prog, ii, warning_message){
  result <- data.frame()
  tryCatch(
    {result = chatgptscrapeR:::scrape_chatgpt_(x)},
    error = function(e) {
      msg = paste0("<p class='text-danger'>",
                   bsicons::bs_icon("x-circle-fill", size = "1.5rem"),
                   conditionMessage(e),"</p>")
      warning_message(c(warning_message(),msg))
    },
    warning = function(w) {
      msg = paste0("<p class='text-warning'>",
                   bsicons::bs_icon("exclamation-triangle-fill", size = "1.5rem"),
                   conditionMessage(w),"</p>")
      warning_message(c(warning_message(),msg))
    }
  )
  incProgress(prog)
  ii <- ii + 1
  result
}

retrieveConversations <- function(session, input, data, convoColumns, dataConvo, warning_message) {
  colz <- req(input$columnSelectors)
  col <- req(input$urlSelect)
  datz <- req(data())
  ii <- 1
  withProgress(message = 'Retrieving conversations', value = 0, {
    prog <- 1/(nrow(datz)+1)
    convoz <- data.frame(tidyr::unnest(dplyr::mutate(datz, 
                 res = purrr::map(!!dplyr::sym(col), \(x) scrape(x,prog,ii, warning_message))), res))
    
    convoColumnsz <- names(convoz)
    convoColumns(convoColumnsz)
    dataConvo(convoz)
    incProgress(prog, message = paste("Processing..."))
    
    updateCheckboxGroupInput(session, "convoColumnSelectors", 
                             choices = names(convoz), 
                             selected = names(convoz))
    updateTabsetPanel(session, "tabs", 
                      selected = "Conversations")
    
    setAnalysis(session, dataConvo)
  })
}

setAnalysis <- function(session, dataConvo) {
  # selectInput("messsage", "Selecte column", choices = names(dataConvo()))
  # selectInput("who", "Selecte role", choices = unique((dataConvo())$message.author.role))
  updateSelectInput(session, "messsage", choices = c(names(dataConvo()),"All"), selected = names(dataConvo())[1])
  updateSelectInput(session, "who", choices = c(unique((dataConvo())$message.author.role),"All"), selected = names(dataConvo())[1])
}

checkUrl <- function(x) {
  stringr::str_detect(x, "http") & stringr::str_detect(x, "chat")
}