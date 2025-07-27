#' @columns_must_not_have_EMPTY_cells(): checks that all columns have non-missing AND non-empty values (empty strings are NOT accepted):
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


source_parent("non_missing_value")

columns_must_not_have_EMPTY_cells <- function(df, list__not_empty_cols, message = NULL) {
  
  ## Input Validation: All columns specified must in the dataframe being tested
  cols_to_test = list__not_empty_cols %>% flatten_chr()
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
        unique_values != ""
      )
      
      return(valid)
      
    }) 
  
  ## Test Failed
  if (any(col_results == F)){
    cols_error = cols_to_test[col_results == F]
    warning(glue("Columns {paste(cols_error, collapse = ', ')} have missing values"))
    return(F)
  }
  
  # Test Passed
  if (!is.null(message)){
    cli_alert_info("Test Passed: columns_must_not_have_EMPTY_cells() {message}")
  } else {
    cli_alert_info("Test Passed: has_columns()")
  }
  return(TRUE)
}
 
 