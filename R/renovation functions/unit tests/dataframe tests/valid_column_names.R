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
      
valid_column_names = function(df, local_context, cube_type = 'all'){
  
  { # Input Validation --------------------------------------------------------
    
    if (!cube_type %in% c('data','metadata','all')) cli_abort("valid_column_names Input Error: cube_type {cube_type} was not found in the admin layer schema.")
    
  }
  
  { # Setup -------------------------------------------------------------------
    
    ## Get acceptable columns for cube type
    vec__valid_columns = case_when(
      cube_type == 'data' ~ list(c(local_context$vec__admin_data_composite_keys, 
                                   local_context$vec__admin_data_columns_all)),
      cube_type == 'metadata' ~ list(c(local_context$vec__admin_final_metata_cube_required_columns,
                                       local_context$vec__admin_metadata_columns_all,
                                       local_context$vec__admin_metadata_composite_keys) %>% 
                                       unique()),
      cube_type == 'all' ~ list(c(local_context$df_admin_layer_schema$name))
    ) %>% 
      unlist()
    
  }
  
  { # Test --------------------------------------------------------------------

    ## Check for invalid columns
    vec__invalid_cols_in_df = names(df) %>% discard(~.x%in%vec__valid_columns)
    failed = length(vec__invalid_cols_in_df) > 0
    
  }
  
  { # Result ------------------------------------------------------------------
    if (failed) {
      warning(glue("Test failed: valid_column_names() - The following columns are not valid for the {cube_type} cube: {paste(vec__invalid_cols_in_df, collapse = ', ')}"))
      return(FALSE)
    }
    cli_alert_info("Test passed: valid_column_names()")
    return(T)
  }

}

 