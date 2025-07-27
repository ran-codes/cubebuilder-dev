#' we have some metadata stored by  packged iso2 values. This funciton unpacks and tidies (make those packed cell values long)
#' The input is dataframe, the output is another dataframe whose iso2 column has been unpacked.
#' Note that the input 'packed' input iso2 could be a string  which contains seprated iso2 or a `_all` key
#'   - string = '_all'
#'   - string = 'BR;MX'

unpack_iso2_string = function(string, i){
  
  if (string == '_all'){
    countries  = i$xwalk_iso2$iso2
  } else {
    countries  = string %>% 
      str_split_1(";") %>% 
      str_trim() %>% 
      unlist()
  }
  
  list_countries = list(countries)
  
  return(list_countries)
}


unpack_iso2 = function(df, i){
  
  if (!'iso2'%in%names(df)) return(df)
  
  df_iso2_unpacked = df %>% 
    rowwise() %>% 
    mutate(iso2 = unpack_iso2_string(iso2, i)) %>% 
    unnest(iso2) 
  
  return(df_iso2_unpacked)
}
