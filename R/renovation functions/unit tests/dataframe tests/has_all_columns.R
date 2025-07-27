
has_all_columns <- function(df, context) {
  
  missing_composite_keys = context$vec__admin_composite_keys_all %>% discard(~ .x %in% names(df))
  
  if (length(missing_composite_keys) > 0) {
    warning(paste("The following data composite keys are missing from the df:", missing_composite_keys))
    return(F)
  }
  
  # All checks passed
  cli_alert_info("Test Passed: has_all_columns() - all composite keys")
  return(TRUE)
}