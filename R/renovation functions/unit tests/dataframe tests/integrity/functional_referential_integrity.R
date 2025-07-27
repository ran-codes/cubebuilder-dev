#' This is less stringent that full_referential_integrity which requires row level integrity for each combination of composite keys:
#'     - essentially just doesn't require the same number of rows. but the keys should eb completely covered in both. This
#'       is usually used to validate the final metadata cube against the final data cube without merging to prelimianry - check the merging
#'       would be consistent.
#' This is more stringent than left_referential_integrity which requires just left side to be consistent subset with a right side  
#' both in terms of:
#'     - structural subset: left side composite keys could be a subset of the right side (e.g. metadata cube vs df_data cube)
#'     - referential subset: even with the structural subset of the right side, the left side doesn't have to match fully and could be a 
#'                      structurral consistent subset of the the right side (e..g partiioend metadata)
#' 
#' This one is in the middle and requires
#'     - referential consisetency: left side must be a structurally consistent subset of the right side
#'        - for common composite keys both sides need to have consistency
#'     - but allows for structural susbet: left side composite keys could be a subset of the right side (e.g. metadata cube vs df_data cube)
#'        - no need for same number of rows
#'        - no need for all same composite keys to be present
#' 
#' Example
#'   df1 = raw_metadata_cube; df2 = template_metadata_cube
#'   df1 = validated_final_metadata_cube; df2 = context$final_data_cube

functional_referential_integrity <- function(df1, df2, context) {
  
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
    
    cli_alert("Functional Referential Integrity Test started")
  }
  
  { # Tests -------------------------------------------------------------------
    
    ##  Get Left composite Keys (1-way Structural test - All Keys in left are in right)  -------------------------------------------------------------------
    { if (!left_structural_integrity(df1, df2, context)){
        warning("Left is not structurally consistent with right")
        return(FALSE)
      }  
      df1_composite_keys = context$vec__admin_composite_keys_all %>% keep(~.x%in%names(df1))
      cli_alert_info("1-way left-sided structural test passed")
    }
    
    
    ## Full composite key consistency test (based keys in left side keys )  -------------------------------------------------------------------
    {
      list_composite_keys = list(df1_composite_keys)
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