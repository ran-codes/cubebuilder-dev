#' Takes in a data frame and checks if all values are utf8 valid
#'   returns boolean TRUE if valid
#'   returns a dataframe containing invalid characters 
#' Performance:
#'    - 1 second per 3 million rows of df_data_final
#'    
#'    Example:
#'    
#'        df = df_data_int

valid_utf8_df = function(df){
 
  ## Test
pass =  names(df) %>% 
  discard(~.x%in%c('Shape','geometry')) %>% 
  map_lgl(~{
    df %>%
      distinct(across(all_of(.x))) %>%
      pull(.x) %>% 
      replace_na('NA') %>%
      utf8::utf8_valid() %>% 
      all()
  }) %>% 
  all()

 
{ # Return ------------------------------------------------------------------
  if (pass){
    cli_alert_info("Test passed: valid_utf8_df()")
    return(TRUE)
  } else {
    cli_alert_error("Test failed: valid_utf8_df()")
    return(FALSE)
  }
  
  }
}
