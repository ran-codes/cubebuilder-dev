#' we take a list of codebooks and a particular column name. This fucntion will search throught he codbeooks 
#' select the table that contains the specified column name then pull the values and return as unique vector of 
#' values
#' 
#' @param list_codebook: the list of codebooks, could be either base__ or int__
#' @param column_name: the column name you want to pull data from
#' 


return_codebook_field_value = function(list_codebook, column_name){
  
  vec__value = list_codebook %>% 
    map(~{
      columns_tmp = names(.x)
      if (column_name%in%columns_tmp){
        .x %>% 
          pull(sym(column_name)) %>% 
          unique() %>% 
          return()
      } else {
        return(NULL)
      }
    }) %>% 
    compact() %>% 
    unlist()
  
  return(vec__value)
}