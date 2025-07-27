#'
#'
#'
#' Example:
# row = df_publications_raw %>% slice(1)
# # row = df_publications_raw %>% filter(doi == '10.1038/s41591-020-01214-4')
# list_authors_pmc = row$authorInfo[[1]]
# list_authors_pm = row$authorInfoPM[[1]]
# # authorItem = list_authors_pm %>% tail(1) %>% .[[1]]
# authorItem = list_authors_pm[[1]]

  
  
parse_pubmed_efetch_authors = function(list_authors_pm){

  op_single_author = function(authorItem){
    name_tmp = glue("{authorItem$ForeInitials} {authorItem$LastName}")
    collectiveName_tmp = authorItem$CollectiveName
    if (!is.na(authorItem$CollectiveName)) {
      return(collectiveName_tmp)
    } else {
      return(name_tmp)
    }
  }
  
  list_authors_pm %>% 
    map(~op_single_author(.x)) %>% 
    paste(collapse = ', ')
  
  
}
