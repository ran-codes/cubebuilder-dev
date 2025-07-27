#'This is an Arrow friendly version of the assertr `has_names` function.
#' 
#'
#'  Examples
#'     list__columns = list(vec__expected_composite_keys)
#'     


has_columns <- function(df, list__columns, message = NULL) {
  
  ## Setup
  expected_columns = list__columns %>% flatten_chr()

  
  ## Test validation
  if (length(expected_columns) == 0)   return(T)

  ## Test
  vec__missing_columns = expected_columns %>% discard(~.x%in%names(df))
  failed = length(vec__missing_columns > 0)
  
  ## Return result
  if (failed){
    warning(glue("Expected columns are missing: {str_c(vec__missing_columns, collapse = ', ')}"))
    return(F)
  } else {
   
   
    if (!is.null(message)){
      cli_alert_info("Test Passed: has_columns() {message}")
    } else {
      cli_alert_info("Test Passed: has_columns()")
    }
    return(TRUE)
  }
  
}
