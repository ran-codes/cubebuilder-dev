#' Takes in a data frame and checks if all values are utf8 valid
#'   returns boolean TRUE if valid
#'   returns a dataframe containing invalid characters 

validate_df_utf8  = function(df){
  
 
  ## Pivot long then check each value for utf8 encoding
  df_error = df %>% 
    as_tibble()%>%
    select(-any_of(c('Shape','geometry'))) %>% 
    mutate_all(~as.character(.x)) %>% 
    mutate(row = row_number()) %>% 
    pivot_longer(cols = -row) %>% 
    mutate(utf8 = utf8::utf8_valid(value)) %>% 
    filter(!utf8)
  valid_utf8 = nrow(df_error) == 0 
  
  ## Return results
  if (valid_utf8) {
    return(T)
  } else {
    cli_alert_danger("UTF8 Encoding error!")
    return(df_error)
  }
}
