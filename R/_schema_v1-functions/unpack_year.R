#' we have some metadata stored by year ranges. This funciton unpacks and tidies (make those packed cell values long)
#' The input is dataframe, the output is another dataframe whose year column has been unpacked.
#' Note that the input 'packed' input year could be a string  which contains years, year-ranges or seperators (;)
#'
#' @param df: (dataframe) input dataframe whose year column will be unpacked from ranges/sep to tidy
#' 
#' 



#'   - string_tmp = '_all'
#'   - string_tmp = '2012'
#'   - string_tmp = '2020'
#'   - string_tmp = '2012-2016'
#'   - string_tmp = '2003-2005;2012-2016; 2018-2022'
#'   - string_tmp = '9999_T1'

unpack_year_string = function(string_tmp){
  
  base_exceptions = c('9999_T1','9999_T2')
  
  if (string_tmp == '_all'){
    years = 1970:2030 %>% as.character()
  } else if (string_tmp %in% base_exceptions) {
    years = string_tmp
  } else {
    years  = string_tmp %>% 
      str_split_1(";") %>% 
      str_trim() %>% 
      map(~{
        range__vec = .x %>% 
          str_split("-") %>% 
          unlist() %>% 
          as.numeric()
        if (length(range__vec)==1){
          list_years = list(as.character(range__vec))
        } else {
          list_years = list(as.character(range__vec[1]:range__vec[2]))
        }
        return(list_years)
      }) %>% 
      unlist()
  }
  
  
  list_years = list(years)
  
  
  return(list_years)
}


unpack_year = function(df, keep_origin = F){
  
  if (!'year'%in%names(df)) return(df)
  
  if (keep_origin == F){ 
    dfa = df %>% 
      rowwise() %>% 
      mutate(year = unpack_year_string(year)) %>% 
      unnest(year)
    return(dfa)
  }
  
  if (keep_origin) {
    df2 =  df %>% 
      rowwise() %>% 
      mutate(year_origin = year,
             year = unpack_year_string(year)) %>% 
      unnest(year) 
    return(df2)
  }
  
}
