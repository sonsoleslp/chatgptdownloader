
ui <- fluidPage(theme = shinytheme("lumen"),
          tags$head(
            tags$title("chatGPTscrapeR"),
            tags$link(rel="icon", href="favicon.png"),
            tags$link(rel="shortcut icon", href="favicon.png")
          ),
          tags$style(HTML("
  .datatables {overflow: auto;}
  .checkbox label {
    overflow: hidden;
    text-overflow: ellipsis;
    text-wrap: nowrap;
  }
  label {
    font-weight: bold;
  }
  .nav-tabs {
    margin-bottom: 1em;
  }
  #warning_note {
   margin-bottom: 1em;
   padding: 1em;
  }
  
  #warning_note p {
   margin-bottom: 0em;
  }
  
  #warning_note p svg {
   margin-right: 0.5em;
  }
  
  .dash h3 {
    color: white;
  }
  .dash h3 svg {
    color: white;
    margin-right: 10px;
  }
  
  .dash-title {
      margin-top: 0px;
  }
  .dash-numbers {
    display: flex;
    align-items: center;
  }
  
  text {
    font-family: inherit;
  }
  ")),
          titlePanel(
            div(
              img(src = "favicon.png", height = "30px", style = "margin-right: 10px;vertical-align:sub;"),
              "chatGPTscrapeR"
            )
          ),
          tabsetPanel(id = "tabs",
                      tabPanel("Data View", 
                               sidebarLayout(
                                 sidebarPanel(
                                   fileInput("file", "Upload a file", accept = c(".csv",".xlsx",".xls",".tsv",".RDS",".sav",".psv",".feather",".parquet")),
                                   uiOutput("columnSelectors"),
                                   uiOutput("urlSelect"),
                                   bsButton("nextButton", label = "Next", style = "info"), 
                                   width = 3
                                 ),
                                 mainPanel(
                                   dataTableOutput("dataView", width = "100%"),
                                   width = 9
                                 ) )),
                      tabPanel("Conversations", 
                               tabPanel("Conversation data", 
                                        sidebarLayout(
                                          sidebarPanel(
                                            uiOutput("convoColumnSelectors"),
                                            bsButton("applyButton", label = "Preview", style = "primary"), 
                                            bsButton("select_all_button", label = "Select all", style = "info"), 
                                            downloadLink("downloadData", "Download", class = "btn btn-warning"),
                                            width = 3
                                          ),
                                          mainPanel(
                                            htmlOutput("warning_note", class = "alert alert-dismissible alert-primary"),
                                            dataTableOutput("dataViewConvo", width = "100%"),
                                            width = 9
                                          )
                                        )
                               )
                      ),
                      tabPanel("Statistics",
                               fluidRow(
                                 # Top Stats Boxes using bsButton for better styling
                                 column(3, 
                                        div(h3("Total conversations", class = "dash-title"), 
                                            h3(bsicons::bs_icon("folder-fill", size = "3rem"),
                                               textOutput("n_conv", inline = T), class = "dash-numbers"), 
                                            class = "dash alert alert-danger")
                                 ),
                                 column(3, 
                                       div(h3("Total Interactions", class = "dash-title"), 
                                           h3(bsicons::bs_icon("chat-fill", size = "3rem"),
                                              textOutput("num_interactions", inline = T), class = "dash-numbers"), 
                                                 class = "dash alert alert-warning")
                                 ),
                                 column(3, 
                                        div(h3("Avg. User Msg. Length", class = "dash-title"), 
                                            h3(bsicons::bs_icon("person-fill", size = "3rem"),
                                               textOutput("avg_interaction_length", inline = T), class = "dash-numbers"), 
                                                 class = "dash alert alert-info")
                                 ),
                                 column(3, 
                                        div(h3("Avg. GPT Msg. Length", class = "dash-title"), 
                                            h3(bsicons::bs_icon("robot", size = "3rem"),
                                               textOutput("avg_response_length", inline = T), class = "dash-numbers"), 
                                                 class = "dash alert alert-success")
                                 )
                               ),
                               fluidRow(
                                 column(4, div(girafeOutput("plot1"))), 
                                 column(4, div(girafeOutput("plot2"))),
                                 column(4, div(girafeOutput("plot3")))
                                 
                               )#,fluidRow(column(6, div(wordcloud2Output("wordcloudUser"))),column(6, div(wordcloud2Output("wordcloudGPT"))))
                               
                          )
                      
                      
          )
)