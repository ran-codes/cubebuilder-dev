#' This test checks correct structure and content of composite keys within a single table.
#' Specifically, the test checks that:
#' 1. Expected composite key columns are present
#' 2. Unexpected composite key columns are not present
#' 3. Verify expected non-empty composite key column values 
#' 4. Verify expected empty composite key column values
#' 
#' Example
#' 
#'     df = df_data_int


composite_key_integrity <- function(df, local_context, cube_type) {
  
  
  { # Setup -------------------------------------------------------------------

    cli_alert("Start Composite Key Integrity Test")
    
    ## Obervation Type
    observation_type_tmp = df %>% 
      select(observation_type) %>% 
      distinct() %>% 
      collect() %>% 
      pull(observation_type)  
    
    ## Expected keys present
    if (cube_type == 'data') vec__expected_composite_keys = local_context$vec__admin_data_composite_keys
    if (cube_type == 'metadata') vec__expected_composite_keys = local_context$vec__admin_metadata_composite_keys
    
    ## Unexpected keys present
    vec__unexpected_composite_keys = local_context$vec__admin_composite_keys_all %>% discard(~.x%in%vec__expected_composite_keys)
    
    ## List of all never_empty composite keys (Content)
    if (cube_type == 'data') vec__never_empty_composite_keys = local_context$vec__admin_data_composite_keys_never_empty
    if (cube_type == 'metadata') vec__never_empty_composite_keys = local_context$vec__admin_metadata_composite_keys_never_empty
    if (observation_type_tmp == 'record-level') vec__never_empty_composite_keys = vec__never_empty_composite_keys %>% discard(~.x=='geo')
    
    ## List of compoiste keys that must be empty (Content)
    if (observation_type_tmp == 'area-level') vec__must_be_empty_composite_keys = c()
    if (observation_type_tmp == 'record-level') vec__must_be_empty_composite_keys = c('geo')
    
  }
  
  { # Test -------------------------------------------------------------------
    
  df_validated = df  %>%
    ## Expected columns are present and not NA/NULL
    verify(has_columns(., list(vec__expected_composite_keys))) %>% 
    verify(columns_must_not_have_NA_NULL_cells(., list(vec__expected_composite_keys))) %>% 
    ## Unexpected columns are not present
    verify(does_not_have_columns(., list(vec__unexpected_composite_keys))) %>% 
    ## Verify expected non-empty columns
    verify(columns_must_not_have_EMPTY_cells(.,list(vec__never_empty_composite_keys))) %>%
    ## Verify expected empty columns
    verify(columns_must_be_EMPTY(.,list(vec__must_be_empty_composite_keys)))
  
  }
  
  { # Result ------------------------------------------------------------------
    cli_alert_success("Test passed: composite_key_integrity()")
    return(TRUE)
  }
 
}

