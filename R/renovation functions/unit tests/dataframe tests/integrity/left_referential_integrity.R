#' Tests that all combinations of composite keys in left df are present in right df
#' 
#'  Usage:
#'     df %>%
#'         verify(left_referential_integrity(., final_data_cube, context),  error_fun = assertr::error_report) 
#'
#'  Examples
#'     df1 = final_metadata_cube; df2 = final_data_cube
#'     df1 = validated_final_metadata_cube; df2 = context$final_data_cube 

left_referential_integrity <- function(df1, df2, context) {
  
  ## Input validation
  valid_object_1 = any(c('data.frame', 'ArrowObject') %in% class(df1)) 
  valid_object_2 = any(c('data.frame', 'ArrowObject') %in% class(df2)) 
  if (!valid_object_1 || !valid_object_2) {
    stop("Both inputs must be dataframes")
  }
  

  ## Input validation: If both are empty data frames consistency does not matter, as no downstream joins. Return valid
  if (nrow(df1) == 0 & nrow(df2) == 0) {
    return(TRUE)
  }
  
  ## Input validation: Left Structural Integrity
  if (!left_structural_integrity(df1, df2, context)){
    warning("Left is not structurally consistent with right")
    return(FALSE)
  }
  
  ## Input Validation: If both empty the there is indeed referential integrity (assuming structural integrity)
  if (nrow(df1) == 0 & nrow(df2) == 0) {
    return(TRUE)
  }
  
  ## Test Composite keys combinations
  composite_keys <- context$vec__admin_composite_keys_all %>% keep(~.x%in%names(df1)) 
  df_key_combinations_left <- df1 %>% 
    select(all_of(composite_keys)) %>% 
    mutate(across(everything(), as.character)) %>%  # Convert all to character
    distinct() %>% 
    collect()
  df_key_combinations_right <- df2 %>% 
    select(all_of(composite_keys)) %>% 
    mutate(across(everything(), as.character)) %>%  # Convert all to character
    distinct() %>% 
    collect()
  df_invalid_combinations_left = anti_join(df_key_combinations_left, df_key_combinations_right, by = composite_keys)
  
  ## Test Failed
  if (nrow(df_invalid_combinations_left) != 0) {
    warning(glue("Left has {nrow(df_invalid_combinations_left)} invalid combinations of composite keys that are not present in right"))
    return(FALSE)
  }
  
  # Test Passed
  return(TRUE)
}