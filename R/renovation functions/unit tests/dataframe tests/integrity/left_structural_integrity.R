#' Tests that all composite keys in left df are in right df
#' 
#' Params:
#' @df1: This could be a in-memory dataframe or out-of-memory Arrow object
#' @df2: This could be a in-memory dataframe or out-of-memory Arrow object
#' 
#' Example
#' 
#'     df1 = final_metadata_cube; df2 = final_data_cube

left_structural_integrity <- function(df1, df2, context) {
  
  ## Input validation
  valid_object_1 = any(c('data.frame', 'ArrowObject') %in% class(df1)) 
  valid_object_2 = any(c('data.frame', 'ArrowObject') %in% class(df2)) 
  if (!valid_object_1 || !valid_object_2) {
    stop("Both inputs must be dataframes")
  }
  
  ## Test
  vec__keys_in_left = names(df1) %>% keep(~.x%in%context$vec__admin_composite_keys_all)
  vec__keys_in_right = names(df2) %>% keep(~.x%in%context$vec__admin_composite_keys_all)
  extra_keys_in_left = vec__keys_in_left %>% keep(~! .x%in%vec__keys_in_right)
  is_consistent_left = length(extra_keys_in_left) == 0
 
  
  ## Test Failed
  if (!is_consistent_left) {
    warning("Left is not structurally consistent with right. Extra keys in left: ", extra_keys_in_left)
    return(FALSE)
  } 
  
  ## Test Passed
  return(TRUE)
}

 