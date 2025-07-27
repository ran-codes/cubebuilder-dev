make_request <- function(endpoint, 
                         querystring = "", 
                         method = "GET", 
                         body = NULL, 
                         body_format_json = F) {
  Sys.sleep(0.34) # notion api limit is 3 requests per second
  
  url <- glue("https://api.notion.com/v1/{endpoint}{querystring}")
  
  headers <- c(
    "Authorization" = secret_notion_api_key,
    "Content-Type" = "application/json",
    "Notion-Version" = "2022-02-22"
  )
  
  body_json = body
  if (!body_format_json) body_json =  toJSON(body, auto_unbox = TRUE)
  response <- VERB(
    verb = method,
    url = url,
    body = if (!is.null(body)) body_json,
    add_headers(headers)
  )
  
  if (http_error(response)) {
    stop(glue("Request returned status code {status_code(response)}
         Response text: {content(response, 'text')}"))
  }
  
  content(response, "parsed")
}