#' @columns_must_be_non_NA_NULL(): checks that all columns have non-missing AND non-empty values (empty strings are NOT accepted):
#'      - must be character
#'      - not NA
#'      - not NULL
#'      - not empty string
#'      list__non_NA_NULL_cols
#' 
#' 
#' Usage:
#'     df = df_data_int %>% slice(1:1000); list__cols = list__expected_complete_columns
#'     list__cols = list(c('var_name''))
#'     list__cols = list(context$vec__admin_composite_keys_all)
#'   
#'   list__not_NA_NULL_cols = list(vec__expected_composite_keys)

source_parent("non_missing_value")
 

columns_must_not_have_NA_NULL_cells <- function(df, list__not_NA_NULL_cols, message = NULL) {
  
  { # Setup --------------------------------------------------------------------
    
    cols_to_test = list__not_NA_NULL_cols %>% flatten_chr()
    
  }
  
  { # Input Validation --------------------------------------------------------

    if (any(!cols_to_test %in% names(df))){
      warning(glue("column names {paste(setdiff(cols_to_test, names(df)), collapse = ', ')} not in df"))
      return(F)
    }
    
  }
  
  
  { # Test ---------------------------------------------------------------------
    ## Test for not empty: not NA, not NULL or not empty string
    col_results = cols_to_test %>% 
      map_lgl(~{
        
        unique_values = df %>%
          distinct(across(all_of(.x))) %>%
          collect() %>% 
          pull(.x)
        
        valid =  all(
          !is.na(unique_values),
          !is.null(unique_values)
        )
        
        return(valid)
        
      }) 
    
    
  }
  
  ## Test Failed
  if (any(col_results == F)){
    cols_error = cols_to_test[col_results == F]
    warning(glue("ERROR - Some cells in columns are expected to be not NA or NULL but are: {paste(cols_error, collapse = ', ')}"))
    return(F)
  }
  
  # Test Passed 
  
  if (!is.null(message)){
    cli_alert_info("Test Passed: columns_must_not_have_NA_NULL_cells() {message}")
  } else {
    cli_alert_info("Test Passed: has_columns()")
  }
  return(TRUE)
}

 