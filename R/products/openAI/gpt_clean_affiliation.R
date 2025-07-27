#' called gpt3.5 to sumamrize an abstract
#' 
#' Example:
#' dirty_aff = "Urban Health Collaborative, Dornsife School of Public Health, Drexel University, Philadelphia, PA, United States."
#' dirty_aff = "Urban Health Collaborative, Drexel Dornsife School of Public Health, 3600 Market Street, Philadelphia, PA, 19104, USA."
#' dirty_aff = "Urban Health Collaborative, Dornsife School of Public Health, Drexel University, Philadelphia, PA, United States."
#' dirty_aff = "Urban Health Collaborative, Dornsife School of Public Health, Drexel University, Philadelphia, PA, United States."


get_clean_affiliation = function(dirty_aff){
 
  dotenv::load_dot_env(file = ".env")
  GPT_API_KEY <- Sys.getenv("GPT_API_KEY")   
  
  prompt = glue("I have a  string of a publication affiliation. These are very unstandardized in that 
some have email address or physical addresses. Can you clean this string by removing all email and 
physical addresses then standardizing the casing of the remaining text in a way that is human readable. Try to standardize the result so that other queries would match.
The dirty affiliation to be cleaned is: `{dirty_aff}`. In the reponse only include the result and no other text.")
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions", 
    add_headers(Authorization = paste("Bearer", GPT_API_KEY)),
    content_type_json(),
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
  
  result = content(response)
  
  summary =  result$choices[[1]]$message$content
  
  return(summary)
  
 }
 