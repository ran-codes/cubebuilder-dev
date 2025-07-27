#'This is an Arrow friendly version of the assertr `has_names` function but just in reverse.
#'
#'  Examples
#'     list__columns = list(vec__expected_composite_keys)
#'     


does_not_have_columns <- function(df, list__columns, message = NULL) {
  
  ## Setup
  unexpected_columns = list__columns %>% flatten_chr()
  
  ## Test validation
  if (length(unexpected_columns) == 0)   return(T)
  
  ## Test
  vec__unexpected_cols = names(df) %>% keep(~.x%in%unexpected_columns)
  failed = length(vec__unexpected_cols > 0)
  
  ## Return result
  if (failed){
    warning(glue("Unpexted columns are missing: {vec__unexpected_cols}"))
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


