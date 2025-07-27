#'  Just a content check sepcific for area-level data that checks that geo and salid length are correclty matched
#'  So L1AD should have 6 characters and L2 should have 8 characters
#'
#'
#'   Example
#'      df = df_data_int


valid_salid_geo <- function(df) {
  
  { # Setup -------------------------------------------------------------------
    
    ## Observation Type
    observation_type_tmp = df %>% 
      select(observation_type) %>% 
      distinct() %>% 
      collect() %>% 
      pull(observation_type)   
  }
  
  
  { # Input Validation --------------------------------------------------------

    ## Input validation - This test is only for 'area-level' observations, if not, return TRUE
    if (observation_type_tmp != 'area-level') return(T)
    
  }
  
  { # Test --------------------------------------------------------------------

    df_invalid_salid_geo = df %>% 
      select(geo, observation_id) %>% 
      distinct() %>% 
      collect() %>% 
      mutate(nchar_salid = nchar(observation_id),
             valid_geo_salid = case_when(
               geo == 'L1AD' ~ nchar_salid == 6,
               geo == 'L2' ~ nchar_salid == 8,
               TRUE ~ T #to add L3 tests later
             ))  %>%
      filter(!valid_geo_salid)
    pass = nrow(df_invalid_salid_geo)==0
  }



  

  { # Result ------------------------------------------------------------------
   
     if (pass) {
       cli_alert_info("Test passed: valid_salid_geo()")
       return(T)
     } else {
       warning(paste("The following composite keys are missing from the data:", missing_composite_keys))
       return(F)
     }
    
  }
}