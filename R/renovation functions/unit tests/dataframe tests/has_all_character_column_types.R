#'  Simple test that all types in a tibble or dataframe or dataframe object has chr type columns
#'  
#'  
#'  - [ ] test in dfs-Strat
#'  - [ ] test with an arrow object

has_all_character_column_types <- function(df) {
   
  { # Setup -------------------------------------------------------------------
    
    ## Class of dataframe
    class_type = case_when(
      'data.frame' %in% class(df) ~ 'data.frame',
      all(c('FileSystemDataset','ArrowObject','Dataset') %in% class(df)) ~ 'parquet',
      TRUE ~ 'ERROR'
    )
    
    ## Input validatiaon
    if (class_type == 'ERROR') {
      stop('Input must be a dataframe or parquet object')
    }
  }
  
  
  { # Test --------------------------------------------------------------------

    ## Dataframe 
    if (class_type == 'data.frame') pass = all(map_lgl(df, is.character))
  
    ## Parquet 
    if (class_type == 'parquet') {
     pass =  dfa$schema$fields %>% 
        map_lgl(~{
          .x$type$ToString() == 'string'
        }) %>% 
        all()
    }
    
  }
  
  
  { # Return ------------------------------------------------------------------

    ## Return result
    if (!pass) {
      warning('Not all columns are character type')
      return(F)
    } else {
      cli_alert_info("Test Passed: has_all_character_column_types()")
      return(T)
    }
    
  }
}
