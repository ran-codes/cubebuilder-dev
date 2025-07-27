no_trailing_seperator <- function(value) {
  if (is.character(value) || is.factor(value)) {
    ifelse(is.na(value), TRUE, str_sub(as.character(value), -1) != ";")
  } else {
    # For non-character and non-factor columns, consider them as passing the test
    rep(TRUE, length(value))
  }
}

valid_no_trailing_seperator <-  function(df, local_context){
  
  ## Don't ened to test composite keys
  df_without_composite_keys = df %>% 
    select(-any_of(local_context$vec__admin_composite_keys_all))
  
  ## For each column pull unique values and run no_trailing_seperators test
  pass = names(df_without_composite_keys) %>% 
    map_lgl(~{
      
      pass = df_without_composite_keys %>% 
        select(!!!.x) %>% 
        distinct() %>%
        pull(1) %>% 
        map_lgl(function(x) {
          pass = no_trailing_seperator(x)
          if (!pass) cli_abort("Trailng seperator found! ERror, debug. Will improve error message in future.")
          return(pass)
          }) %>% 
        all()
      if (!pass) cli_abort("Trailng seperator found! ERror, debug. Will improve error message in future.")
      return(pass)
      }
    ) %>% 
    all()
  
  if (!pass) cli_abort("Trailng seperator found! ERror, debug. Will improve error message in future.")
  return(pass)
  
}
