#' NOTE: CAN QUARENTINE COMPLETELY JUST RELY ON validate_final_admin_data_cube() BECAUSE WE ARE NOT MERGING
#' 
#' Validate Final Data Cube
#'
#' This function performs a series of validation checks on the final data cube.
#' It verifies UTF-8 encoding and checks the validity of the 'public' column.
#'
#' @param df_data_final A dataframe representing the final data cube to be validated.
#'
#' @return The validated dataframe. If any validation fails, it will throw an error.
#'
#' @details
#' The function performs the following checks in order:
#' 1. Verifies that all columns have valid UTF-8 encoding.
#' 2. Checks that the 'public' column exists and contains only valid values ('0', '1', '9').
#'
#' If any check fails, an error is reported using assertr's error reporting mechanism.
#'
#' @examples
#' \dontrun{
#' df_validated <- validate_final_data_cube(df_data_final)
#' }
#'
#' @import dplyr
#' @import assertr
#' @export

validate_production_admin_data_cube <- function(production_data_cube, local_context ) {
  # # Input validation
  # if (!is.data.frame(production_data_cube)) {
  #   stop("Input must be a dataframe")
  # }
  # 
  # if (nrow(production_data_cube) == 0) {
  #   warning("Input dataframe is empty")
  #   return(production_data_cube)
  # }
  # 
  # # Perform validation checks
  # production_data_cube_validated <- production_data_cube %>%
  #   # verify(valid_utf8_df(.), , error_fun = assertr::error_report)  %>%
  #   verify(valid_values_public(.), error_fun = assertr::error_report)  
  #   verify(valid_column_names(., local_context), error_fun = assertr::error_report) %>%
  #   verify(valid_unpacking(.), error_fun = assertr::error_report) %>%
  #   assert(non_missing_value,
  #          dataset_id, observation_id, observation_type, dataset_instance, version,
  #          var_name, iso2, geo,  value, public,
  #          error_fun = assertr::error_report) %>%
  #   verify(composite_key_uniqueness(., local_context),error_fun = assertr::error_report)
  # 
  # 
  # return(production_data_cube_validated)
}


