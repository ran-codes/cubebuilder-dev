#' called gpt3.5 to sumamrize an abstract
#' 
#' Example:
#' pmid = '123'
#' abstract = "The SALURBAL (Urban Health in Latin America) Project is an interdisciplinary multinational network aimed at generating and disseminating actionable evidence on the drivers of health in cities of Latin America. We conducted a temporal multilayer network analysis where we measured cohesion over time using network structural properties and assessed diversity within and between different project activities according to participant attributes. Between 2017 and 2020 the SALURBAL network comprised 395 participants across 26 countries, 23 disciplines, and 181 institutions. While the cohesion of the SALURBAL network fluctuated over time, overall, an increase was observed from the first to the last time point of our analysis (clustering coefficient increased [0.83-0.91] and shortest path decreased [1.70-1.68]). SALURBAL also exhibited balanced overall diversity within project activities (0.5-0.6) by designing activities for different purposes such as capacity building, team-building, research, and dissemination. The network's growth was facilitated by the creation of new diverse collaborations across a range of activities over time, while maintaining the diversity of existing collaborations (0.69-0.75 between activity diversity depending on the attribute). The SALURBAL experience can serve as an example for multinational research projects aiming to build cohesive networks while leveraging heterogeneity in countries, disciplines, career stage, and across sectors."

gpt_summarize_abstract = function(abstract,pmid){
 
  cli_alert("Start PMD {pmid} GPT API request")
  dotenv::load_dot_env(file = ".env")
  GPT_API_KEY <- Sys.getenv("GPT_API_KEY")   
  
  prompt = glue("Please summarize this abstract for a thumbnail description. The result should be less than 400 characters in length. Abstract: {abstract}")
  response <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions", 
    httr::add_headers(Authorization = paste("Bearer", GPT_API_KEY)),
    httr::content_type_json(),
    encode = "json",
    body = list(
      model = "gpt-3.5-turbo",
      temperature = 1,
      messages = list(list(
        role = "user", 
        content = prompt
      ))
    )
  )
  
  result = httr::content(response)
  
  summary =  result$choices[[1]]$message$content
  
  cli_alert_success("Return GPT Summary for {pmid}")
  return(summary)
  
 }
 