#' Column missi
#' 
#' Usage
#' df %>%
#'     assert(non_missing_value, col1, col2, error_fun = assertr::error_report) 
#'     
#' Example
#'    df = result; list_columns = list(vec__v1_v2_schema_columns)

non_missing_value <- function(value) {
  
  valid =  all(
    !is.na(value),
    !is.null(value),
    value != ""
  )
 
  return(valid)
}



valid_non_missing_value <-  function(df, list_columns, local_context){
  
  ## Setup
  vec_columns_to_test = unlist(list_columns)
  columns_missing = vec_columns_to_test %>% discard(~.x%in%names(df))
  
  ## Input validation: df being test must have specified columns
  if (!all(vec_columns_to_test %in% names(df))) {
    cli_abort("Test failed - valid_non_missing_value(): Some columns being tested are not in the original dataframe including - {paste(columns_missing, collapse = ', ')}")
  }
  
  
  ## For each column pull unique values and run no_trailing_seperators test
  pass = vec_columns_to_test %>% 
    map_lgl(~{
      column_tmp = .x
      pass = df %>% 
        select(!!!column_tmp) %>% 
        distinct() %>%
        collect() %>%
        pull(1) %>% 
        map_lgl(function(x) {
          pass = non_missing_value(x)
          
          if (!pass) cli_abort("Test failed valid_non_missing_value():  the `{column_tmp}` column has missing values. Please fix the missing values before proceeding.")
          return(pass)
        }) %>% 
        all()
      if (!pass) cli_abort("non_missing_value missing found in final metta data errror!!!! ERror, debug. Will improve error message in future.")
      return(pass)
    }
    ) %>% 
    all()
  
  if (!pass) cli_abort("non_missing_value missing found in final metta data errror!!!! ERror, debug. Will improve error message in future.")
  
  cli_alert_info("Test passed - non_missing_value(): {paste(vec_columns_to_test, collapse = ', ')}")
   return(pass)
  
}
