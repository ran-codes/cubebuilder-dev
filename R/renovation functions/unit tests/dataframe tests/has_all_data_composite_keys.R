
has_all_data_composite_keys <- function(df, context) {
  
  missing_composite_keys = context$vec__admin_composite_keys_all %>% discard(~ .x %in% names(df))
  
  if (length(missing_composite_keys) > 0) {
    warning(paste("The following data composite keys are missing from the df:", missing_composite_keys))
    return(F)
  }
  
  # All checks passed
  return(TRUE)
}