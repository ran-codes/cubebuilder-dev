#' simple function to remove all jinija brackets forma  string. input is a stirng out pout is a string but wiht all {{ and }} removed.
#' 
#' @param string (string): input string to remove jinja templating syntax from
#' 
#' Example: x = '{{mortality}}'
#' Example: x = 'text {{mortality}} text'`

remove_templating_syntax = function(x){
  
  cleaned_string = x %>% 
    str_remove_all('\\{\\{')%>% 
    str_remove_all('\\}\\}')
  
  return(cleaned_string)
  
}