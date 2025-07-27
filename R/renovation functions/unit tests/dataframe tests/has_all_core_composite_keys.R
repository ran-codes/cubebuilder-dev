#' THis is a test for required columns. So minimal test. This df msut have these.

has_all_core_composite_keys <- function(df, local_context) {
  
  missing_composite_keys = local_context$vec__admin_metadata_composite_keys %>% discard(~ .x %in% names(df))
  
  if (length(missing_composite_keys) > 0) {
    warning(paste("The following core composite keys are missing from the df:", missing_composite_keys))
    return(F)
  }
  
  # All checks passed
  return(TRUE)
}