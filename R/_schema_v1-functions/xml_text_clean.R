#' Reads in cleaened XML


xml_text_clean = function(node, concat = F){
  text_tmp =   xml2::xml_text(node) %>% 
    stringr::str_replace_all('\n',' ') %>% 
    stringr::str_replace_all('  ', ' ')%>% 
    stringr::str_replace_all('  ', ' ') %>% 
    stringr::str_trim()
  
  if ( (length(text_tmp) > 1) & (concat == T) ) text_tmp = text_tmp %>% paste(collapse = ', ')
  
  return(text_tmp)
}
