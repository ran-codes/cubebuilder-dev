#' @columns_must_be_EMPTY(): checks that all columns have non-missing AND non-empty values (empty strings are NOT accepted):
#'      - must be 
#'         - character
#'         - empty string ''    
#' Usage:
#'     df = df_data_int %>% slice(1:1000); list__cols = list__expected_complete_columns
#'     list__cols = list(c('var_name''))
#'     list__cols = list(local_context$vec__admin_composite_keys_all)
#'   
#'    df %>%  
#'       verify(columns_all_character(.), error_fun = assertr::error_report)

columns_must_be_EMPTY <- function(df, list__must_be_empty_columns) {
  
  ## Input Validation: All columns specified must in the dataframe being tested
  cols_to_test = list__must_be_empty_columns %>% flatten_chr()
  if (any(!cols_to_test %in% names(df))){
    warning(glue("column names {paste(setdiff(cols_to_test, names(df)), collapse = ', ')} not in df"))
    return(F)
  }
  
  ## Test for not empty: not NA, not NULL or not empty string
  col_results = cols_to_test %>% 
    map_lgl(~{
      
      unique_values = df %>%
        distinct(across(all_of(.x))) %>%
        collect() %>% 
        pull(.x)
      
      valid =  all(
        !is.na(unique_values),
        !is.null(unique_values),
        unique_values == ''
      )
      
      return(valid)
      
    }) 
  
  ## Test Failed
  if (any(col_results == F)){
    cols_error = cols_to_test[col_results == F]
    warning(glue("ERROR - Some cells in columns are expected to be not NA or NULL but are: {paste(cols_error, collapse = ', ')}"))
    return(F)
  }
  
  # Test Passed
  return(TRUE)
}