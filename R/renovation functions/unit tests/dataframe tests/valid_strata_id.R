#' Project wide column validation. It not phase specific.
#' We have a master list of accepted columns that we check against.
#' In the future potentially we will have phase specific column validation. (e.g. final_metdata should not have 'value' or 'salid')
#' 
#' @cube_type: default is 'all' so just checks that the columns are any in schema. But specifiying the typ eo cube iwll 
#'            focus the validation to only include fields linkaged to taht cube type.
#'             - 'all': all columns
#'             - 'metadata': composite key + metadata fields
#'             - 'data': composite key + data fields
#'      
#' Usage
#'    df %>% 
#'       verify(valid_column_names(., i), error_fun = assertr::error_report)

#' This test complements
      
valid_strata_id = function(df){
  
  { # Input Validation --------------------------------------------------------
    
   if (!"strata_id" %in% names(df)) {
      warning("Test failed: valid_strata_id() - The column 'strata_id' is missing from the data frame.")
      return(FALSE)
   }
    
  }
  
  { # Setup -------------------------------------------------------------------
    
   vec__strata_id = df %>% 
      select(strata_id) %>% 
      distinct() %>% 
      collect() %>% 
      pull(strata_id)
    
  }
  
  { # Test --------------------------------------------------------------------

    ## Check for invalid columns
    vec__invalid_strata_id = c(
      vec__strata_id %>% keep(~.x %>% str_detect("NA_NA"))
    )

    
    failed = length(vec__invalid_strata_id) > 0
    
  }
  
  { # Result ------------------------------------------------------------------
    if (failed) {
      warning(glue("Test failed: valid_strata_id() - The following strata_id are invalid: {paste(vec__invalid_strata_id, collapse = ', ')}"))
      return(FALSE)
    }
    cli_alert_info("Test passed: valid_strata_id()")
    return(T)
  }

}

 