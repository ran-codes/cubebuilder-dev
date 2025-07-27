#' For raw data tehre are a few things to process to prep for downstream work:
#'    - Update local context with a confidence interval flag
#'    - Cache the data cube and local context (for data processing that takes a while - this freezes results)

process_final_admin_data_cube <- function(validated_int_data_cube, local_context) {
     
  ## Input validation (just check validated_int_data_cube is at least bigger than raw data) 
  if (nrow(validated_int_data_cube) < nrow(local_context$raw_data)) {
    stop("Validated data cube is smaller than raw data cube. This is a problem.")
  }
   
  ## Cache data cube and local context
  validated_int_data_cube %>% arrow::write_parquet(local_context$path_cache_staged_data)
  
  ## Cache intermediate forms of the data cube
  {  #### Metadata Template
    con <- dbConnect(duckdb())
    on.exit(dbDisconnect(con, shutdown = TRUE))
    query <- glue_sql("
      SELECT DISTINCT {`local_context$vec__admin_metadata_composite_keys`*}
      FROM parquet_scan({local_context$path_cache_staged_data})
    ", .con = con)
    metadata_cube_key_template <- dbGetQuery(con, query) %>% as_tibble()
    metadata_cube_key_template %>% write_parquet(local_context$path_cache_metadata_cube_key_template)
  }
  
  ## Return
  cli_alert_success(glue("Cached validated final data cube at {local_context$path_cache_staged_data}"))
  cli_alert_info("Please refresh local context to see bring cached final data cube into local context.")
  return(validated_int_data_cube)
}
