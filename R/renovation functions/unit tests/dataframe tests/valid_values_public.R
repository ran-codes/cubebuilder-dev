#' Check Public Column Validity
#'
#' This function tests a dataframe to ensure it has a 'public' column
#' and that the values in this column conform to SALURBAL standards.
#' It is designed to be used with assertr::verify().
#'
#' @param df A dataframe to be checked.
#' @param valid_public_values A character vector of valid values for the 'public' column.
#'   Default is c('0', '1', '9').
#'
#' @return A logical vector of length 1. TRUE if all checks pass, FALSE otherwise.
#'
#' @details
#' The function performs two checks:
#' 1. Verifies the presence of a 'public' column in the dataframe.
#' 2. Ensures all values in the 'public' column are within the set of accepted values
#'    as per SALURBAL standards (default: 0, 1, 9).
#'
#' If any check fails, the function returns FALSE.
#'
#' @examples
#' library(assertr)
#' df <- data.frame(public = c('0', '1', '9', '1'))
#' df %>% verify(valid_values_public)
#' df <- data.frame(negative = c('0', '1', '9', '1'))
#' df %>% verify(valid_values_public)
#'
#' df_invalid <- data.frame(public = c('0', '1', '2', '9'))
#' df_invalid %>% verify(valid_values_public, error_fun = assertr::error_report)
#'
#' @export
 
valid_values_public <- function(df, valid_public_values = c('0', '1','2','3', '9')) {
 

  
  ## Check if dataframe is empty
  if (nrow(df)  == 0) {
    warning("The input OBT is empty.")
    return(FALSE)
  }
  
  # Check if has public column
  if (!'public' %in% names(df)) {
    warning("No 'public' column found in the dataframe.")
    return(FALSE)
  }
  
  # Check for invalid public values
  vec__unique_public_values = df %>% select(public) %>% distinct() %>% collect() %>%  pull(public)
  invalid_public_values <- setdiff(vec__unique_public_values, valid_public_values)
  if (length(invalid_public_values) > 0) {
    warning(sprintf("Invalid 'public' values found: %s", 
                    paste(invalid_public_values, collapse = ", ")))
    return(FALSE)
  }
  
  # All checks passed
  cli_alert_info("Valid public values test passed")
  return(TRUE)
}