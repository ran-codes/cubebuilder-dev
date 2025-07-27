#' Once we have  intermediate codebooks we process them into final metadata cubes:
#'    1. Denormalize from object to metadata cube
#'    2. Processing:
#'       - Compile any composite source if needed
#'       - left_join of `file_data` to `final_data_cube`
#'    3. Validate final metadata cube
#'    4. Return
#'    
#'    
#'    Partition Example
#'      intermediate_codebook_object = NULL; intermediate_metadata_cube = intermediate_metadata_cube; 
#'      intermediate_codebook_object = intermediate_codebook_object_tmp;  intermediate_metadata_cube = NULL
#'      intermediate_codebook_object = intermediate_codebook_object;  intermediate_metadata_cube = NULL

source_parent('denormalize_codebook_object')

process_final_metadata_cube <- function(intermediate_codebook_object, context, intermediate_metadata_cube = NULL) {
  
  cli_alert("Start processing intermediate codebooks -> final metadata cube{ifelse(is.null(context$partition_tmp),'', paste0(' (partition - ',context$partition_tmp, ')') )}")
 
  #  Denormalize -------------------------------------------------------------------------
  if (is.null(intermediate_metadata_cube)) intermediate_metadata_cube = denormalize_codebook_object(intermediate_codebook_object, context) %>% select(-any_of(c('var_name_raw')))
  if (!is.null(intermediate_metadata_cube)) intermediate_metadata_cube = intermediate_metadata_cube %>% select(-any_of(c('var_name_raw')))
  cli_alert("1. Intermediate codebook_object denormalized into a metadata cube")
  
  # Final Processing -------------------------------------------------------------------------
  final_metadata_cube =  intermediate_metadata_cube %>% 
    mutate_source_inherited_from_var_origin(., context) %>% 
    left_join(arrow::read_parquet(context$path_strata_parquet) %>% 
                select(-var_name_raw) %>% 
                distinct()) %>% 
    verify(full_referential_integrity(., intermediate_metadata_cube, context))
  cli_alert("2. Final Processing done")
  
  # Validate -------------------------------------------------------------------------
  validated_final_metadata_cube = validate_final_metadata_cube(final_metadata_cube, context)
  cli_alert("3. Intermediate metadata cube validated")
  
  # Return -------------------------------------------------------------------------
  detect_compiled_partition = nrow(validated_final_metadata_cube) == nrow(context$metadata_cube_key_template)
  if (any(context$is_not_partitioned, detect_compiled_partition)){
    validated_final_metadata_cube %>% write_parquet(sink = context$path_cache_staged_metadata)
  } else {
    partition_tmp = context$partition_tmp
    partition_cache_path_tmp = glue(context$partitioned_metadata_config$int_metadata_cube_filename_format)
    validated_final_metadata_cube %>% write_parquet(sink = partition_cache_path_tmp)
  }
  cli_alert_success("4. Final metadata cube validated and staged!")
  cli_alert_info("Please refresh local context object to add final metadata cube to local context!")
  return(validated_final_metadata_cube)
  
}

