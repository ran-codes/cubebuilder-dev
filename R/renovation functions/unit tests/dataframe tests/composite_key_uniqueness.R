#' This assumes that the composite keys within a table has passed integrity tests via composite_key_integrity().
#' At this point we are sure we have the correct composite keys and all we want to do now is that
#' for the composite keys we have in our table, there is within table referential integrity. That is 
#' to say they are functional composite keys where each row has a unique combination of the composite keys.
#' 
#' We seperate this from composite_key_integrity() because we want to have a general test that accomidates
#' tables withouth the need to sepcify composite keys that are table sepcific. This is a proejct wide test
#' that checks a table against all keys specified in the admin layer codebook which is stored in global context.
#' 
#' 
#' Example:
#'     df = df_data_int
#'     df = df_cube_data_precensor %>% collect

composite_key_uniqueness = function(df, context, message = NULL){
  
  { # Setup -------------------------------------------------------------------
    potential_intermediate_columns = c('column', 'salid', 'value_iteration')
    keys_to_check = c(context$vec__admin_composite_keys_all, 
                      potential_intermediate_columns)
    existing_cols <- keys_to_check[keys_to_check %in% names(df)]
    table_type = case_when(
      'FileSystemDataset' %in% class(df) ~ 'parquet',
      "data.frame" %in%  class(df) ~ 'data.frame',
      TRUE ~ 'ERROR')
    
    ## Stage intermediate parquet if huge dataframe
    if ( table_type == 'data.frame' & nrow(df) >= 10^6) {
      unlink('tmp.parquet')
      df %>% write_parquet('tmp.parquet')
      df = arrow::open_dataset('tmp.parquet')                     
      table_type = 'parquet'
    }
  }
  
  {# Input Validation --------------------------------------------------------
    
    if (table_type == 'ERROR') {
      warning("The table being tested is not a dataframe or parquet file. Please check the input table.")
      return(FALSE)
    }
    
    if (length(existing_cols) == 0) {
      warning("There are no composite keys in the table being tested; please check the input table.")
      return(FALSE)
    }    
    
  }
  
  {  # Data frame test -------------------------------------------------------------------
    if (table_type == 'data.frame' & nrow(df) <= 10^6) {
      
     
      
      ## Query + Compute   -------------------------------------------------------------------
      df_distinct = df %>%
        select(any_of(keys_to_check)) %>%
        collect() %>% 
        add_count(!!!syms(existing_cols))
    
      df_invalid = df_distinct %>%
        filter(n>1)
      
      # Result   -------------------------------------------------------------------
      valid_composite_key_uniqueness = nrow(df_invalid) == 0
    }
    
  }
  
  { # Arrow test -------------------------------------------------------------------
    if (table_type == 'parquet') {
      
      ## Create Connection  -------------------------------------------------------------------
      con <- dbConnect(duckdb::duckdb())
      on.exit(dbDisconnect(con, shutdown = TRUE))
      
      # Query   -------------------------------------------------------------------
      query <- glue_sql("
    WITH parquet_data AS (
      SELECT * FROM parquet_scan({df$files})
    ),
    distinct_keys AS (
      SELECT DISTINCT {`existing_cols`*}
      FROM parquet_data
    )
    SELECT 
      (SELECT COUNT(*) FROM distinct_keys) AS distinct_count,
      (SELECT COUNT(*) FROM parquet_data) AS total_count
  ", .con = con)
      
      # Compute   -------------------------------------------------------------------
      result <- dbGetQuery(con, query)
      
      # Result   -------------------------------------------------------------------
      valid_composite_key_uniqueness <- result$total_count == result$distinct_count
    }
  }
  
  
  { # Result -------------------------------------------------------------------
    
    ## Unlink tmp cache
    unlink("tmp.parquet")
    
    ## Test Failed
    if (!valid_composite_key_uniqueness){
      warning("Composite key uniqueness validation failed.")
      return(FALSE)
    }
    
    ## Test Passed
    cli_alert_info("Test passed: composite_key_uniqueness() {message}")
    return(T)
  }
  
}
