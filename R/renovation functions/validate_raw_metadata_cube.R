#' This main checks tructue of raw codebooks compared to the tempaltes for consitency, valid columns no dropped variables.
#' - This deprecates i = etl_export_step5(dataset_id_tmp, stage = 'raw', raw_codebook_object, i, qc_only = T) 
#' The majority of content QC will be for final codebooks.
#' 
#' 

validate_raw_metadata_cube <- function(raw_metadata_cube, local_context) {
  
  raw_metadata_cube_validated = raw_metadata_cube   %>%
    ## Composite key Integrity
    verify(composite_key_integrity(., local_context, cube_type = 'metadata')) %>% 
    ## All Columns 
    verify(valid_column_names(., local_context, cube_type = 'metadata'))   %>% 
    ## Others
    verify(full_referential_integrity(., local_context$metadata_cube_key_template, local_context)) %>%
    verify(composite_key_uniqueness(., local_context))
  
  return(raw_metadata_cube_validated)
  
}

process_raw_metadata_object <- function(raw_codebook_object, local_context) {
  
  ## Validate raw codebooks
  raw_metadata_cube = denormalize_codebook_object(raw_codebook_object, local_context, raw = T) %>% select(-var_name_raw)
  valid_raw_metadata_cube = validate_raw_metadata_cube(raw_metadata_cube, local_context)
  
  ## Initialize int codebooks for review if raw pass validation
  if (!file.exists(local_context$int_cdbk_path)) {
    write_salurbal_xlsx(raw_codebook_object, local_context$int_cdbk_path, local_context)
    snapshot_excel(path = local_context$int_cdbk_path)
  }
 
  cli_alert_success("Raw Metadata Cube Validated!")
  return(valid_raw_metadata_cube)
  
}

