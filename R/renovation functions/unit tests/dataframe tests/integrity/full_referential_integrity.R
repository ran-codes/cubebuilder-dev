#' If we test for:
#'    1. Same numebr of rows (same rows)
#'    2. Same composite keys (same columns)
#' Then reuse, functional_referential_integrity.
#'    With the first two things validated and it also pass the last, then 
#'    there is full referential consistency. In other words,
#'    we have the same columns, and same number of rows and each row is 1:1 matched
#'    with between tables then we can be sure there is 100% referential consistency.
#'    
#'    This is oppose to relaxing the first two conditions. which focuses on testing if
#'    a subset of columns are consistent between the two tables. E.g. metadata cube with 
#'    data cube (this does not include the same composite keys - one has `observation_id` and
#'    one doesn't and the test doesnt include `observation_id`) -  this is done in
#'    functional_referential_integrity(). Here we go on step further and make sure both have
#'    the same keys and the same number of rows then the composite keys are matched.
#'    
#'  Examples
#'   df1 = raw_metadata_cube; df2 = context$metadata_cube_template
#'   df1 = raw_metadata_cube; df2 = final_data_cube
#'   df1 = rendered_results; df2 = to_render
#'   df1 = context$final_obt; df2 = context$final_data_cube
#'   df1 =  context$path_cache_staged_obt %>% arrow::open_dataset(); df2 = context$final_data_cube
#'   df1 = staged_obt; df2 =  context$final_data_cube



full_referential_integrity <- function(df1, df2, context) {
  
  { # Setup -------------------------------------------------------------------
    
    ## Input validation: if both have no rows then return TRUE
    if (nrow(df1) == 0 & nrow(df2) == 0) {
      return(TRUE)
    }   
    
    ## Input validation: Must be dataframes or dataframe abstractions
    valid_object_1 = any(c('data.frame', 'ArrowObject') %in% class(df1)) 
    valid_object_2 = any(c('data.frame', 'ArrowObject') %in% class(df2)) 
    if (!valid_object_1 || !valid_object_2) {
      stop("Both inputs must be either dataframes or Arrow objects")
    }
    df1_class = ifelse('data.frame'%in%class(df1),'data.frame','ArrowObject')
    df2_class = ifelse('data.frame'%in%class(df2),'data.frame','ArrowObject')
    
    
    ## Check data scale
    data_scale = ifelse(any(nrow(df1)>10^6, nrow(df2)>10^6),'big','small')
    
    cli_alert("Full Referential Integrity Test started")
  }
  
  { # Tests -------------------------------------------------------------------
    
    ## Get Composite Keys (2-way Structural test) -------------------------------------------------------------------
    {
      if (!left_structural_integrity(df1, df2, context)){
        warning("Left is not structurally consistent with right")
        return(FALSE)
      }
      if (!left_structural_integrity(df2, df1, context)){
        warning("Right is not structurally consistent with left")
        return(FALSE)
      }
      
      ## Because we have 2 side strucatural consistency the keys in on will be the keys in the other
      fully_consistent_composite_keys = context$vec__admin_composite_keys_all %>% keep(~.x%in%names(df1))
      cli_alert_info("2-way Structural test passed")
      
    }
    
    ## Same Number of rows  -------------------------------------------------------------------
    {
      if (nrow(df1) != nrow(df2)) {
        warning("Number of rows in both dataframes do not match")
        return(FALSE)
      }
      cli_alert_info("Same number of rows test passed")
    }
    
    
    ## Full composite key consistency test (based keys in both sides)  -------------------------------------------------------------------
    {
      list_composite_keys = list(fully_consistent_composite_keys)
      if (!composite_referential_integrity(df1, df2, context, list_composite_keys)){
        warning("Data points are not consistent between the two tables based on the provided list of composite keys.")
        return(FALSE)
      } 
      cli_alert_info("Full composite key consistency test passed")
    } 
    
  }
  
  { # Results   -------------------------------------------------------------------
    
    ## No Failed tests return TRUE
    return(TRUE)
    
  }
  
}

