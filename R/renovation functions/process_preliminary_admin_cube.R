process_preliminary_admin_cube = function(context){
  
  { ## Input Validation
    
    #### Validate: Upstream cubes are staged
    if(!all(file.exists(c(context$path_cache_staged_data, context$path_cache_staged_metadata)))) cli_abort("Integration Test Invalid Input: Upstream staged objects do not exist.")
    ds_final_metadata_cube = open_dataset(context$path_cache_staged_metadata) 
    
    #### Validate: Non-redundant columns (other than composite keys)  
    data_cols = context$final_data_cube %>% 
      select(-all_of(context$vec__admin_metadata_composite_keys)) %>% 
      names()
    metadata_cols = context$final_metadata_cube %>% 
      select(-all_of(context$vec__admin_metadata_composite_keys)) %>% 
      names()
    intersect_cols = intersect(data_cols, metadata_cols)
    if (length(intersect_cols) > 0) cli_abort("Integration Test Invalid Input: Data and metadata have redundant columns other than comosite keys.")
    

  }  
  
  
  { ## Stage OBT
    
    #### Connection
    con <- dbConnect(duckdb()) 
    
    #### Query
    query <- glue_sql("
    COPY (
      SELECT 
        {`context$vec__admin_metadata_composite_keys`*},
        {SQL(paste(setdiff(data_cols, 'public'), collapse = ', '))},
        m.public
      FROM parquet_scan({context$path_cache_staged_data}) d
      LEFT JOIN parquet_scan({context$path_cache_staged_metadata}) m
      USING ({`context$vec__admin_metadata_composite_keys`*})
    ) TO {context$path_cache_staged_obt} 
    (FORMAT PARQUET)
  ", .con = con)
    
    ## Execute (40 million rows per minute)
    dbExecute(con, query)
    dbDisconnect(con, shutdown = TRUE)
    return(cli_alert_success('Preliminary Admin Cube (Data + Metadata) staged to `{context$path_cache_staged_obt}`'))
  }
  
}
