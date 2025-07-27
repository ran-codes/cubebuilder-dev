#'
#'
#'
#' Example:
# row = df_publications_raw %>% slice(88)
# list_authors_pm = row$authorInfoPM[[1]]


parse_pubmed_efetch_affiliations = function(list_authors_pm){
  
  
  vec__aff_raw =   list_authors_pm %>% 
    discard(~is.null(.x$Affiliation)) %>% 
    map(~.x$Affiliation %>% str_split(";") ) %>% 
    unlist() %>% 
    str_trim() %>% 
    unique()
  
  
  # vec__aff_flagged = vec__aff_raw %>% 
  #   keep(~.x %>% str_detect('@'))
  # 
  # tibble(aff = vec__aff_raw) %>% 
  #   arrange(aff) %>% 
  #   View()

  return(list(vec__aff_raw))
  
}
