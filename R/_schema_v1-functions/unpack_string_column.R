#' takes in a data frame and a column name that contains string seperated by ;. reutrns a dataframe that unpacks that column
#' 
#' @param input: (dataframe) the starting dataframe.It should contian at least on string oclumn
#' @param column: (string) the name of the string type columnt hat you want to unpack. 
#' 
#' example: df =  read_csv("_shared_storage/0_schema/templates/4-codebook_keys.csv"); column = 'keys'

unpack_string_column = function(df, column){
  
  if (!column%in%names(df)) return(df)
  
  df__unpacked = df %>% 
    rowwise() %>% 
    mutate( across({{column}}, ~unpack_string(.)) ) %>% 
    unnest(!!column)
  
  return(df__unpacked)
}
 