#' This test validates the strta cell content within a data frame. It does not verify structural integrity.
#' But for each strata related column available it checks that they are not NA/NULL and there are no 
#' legacy edge case bugs  such as `_NA_NA` present in strings. 


strata_columns_integrity <- function(df, context) {
  
  
  { # Setup -------------------------------------------------------------------

    cli_alert("Start Strata Content Integrity Test")
    
    df_strata_tmp = df %>% 
      select(any_of(context$vec__admin_strata_definition_table_columns)) %>% 
      distinct() %>%  
      collect() 
    
    vec_available_non_empty = c('dataset_id','dataset_version','dataset_instance','schema_version','var_name','var_name_raw') %>% 
      keep(~.x%in%names(df_strata_tmp))
  }
  
  { # Test -------------------------------------------------------------------
    
    validated = df_strata_tmp  %>% 
      verify(has_all_character_column_types(.)) %>% 
      verify(columns_must_not_have_NA_NULL_cells(
        .,
        list(names(df_strata_tmp)),
        message = 'all strata table columns'))  %>% 
      verify(columns_must_not_have_EMPTY_cells(
        .,
        list(vec_available_non_empty),
        message = 'all strata table composite keys')) %>% 
      verify(valid_strata_id(.))
    
  }
  
  { # Result ------------------------------------------------------------------
    cli_alert_success("Test passed: strata_columns_integrity()")
    return(TRUE)
  }
 
}

