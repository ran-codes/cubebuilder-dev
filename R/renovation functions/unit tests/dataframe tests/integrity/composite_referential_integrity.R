#'functional_referential_integrity
#'
#'
#'   df1 =  local_context$path_cache_staged_obt %>% arrow::open_dataset(); df2 = local_context$final_data_cube
#'  
#'
#'   Dev
#'   df1 = validated_final_metadata_cube; df2 = local_context$final_data_cube; list_composite_keys <- list(c("dataset_id", "dataset_instance", "day", "geo", "iso2", "month","observation_type", "strata_id", "var_name", "version", "year"))
#'        

composite_referential_integrity <- function(df1, df2, local_context, list_composite_keys) {
  
  
  # Setup  ----------------------------------------------------------------
  { 
    ## Unlist vector input
    vector_composite_keys = list_composite_keys %>% unlist()
    
    ## Check data scale
    data_scale = ifelse(any(nrow(df1)>10^6, nrow(df2)>10^6),'big','small')
    
    ## Input validation: utility cahce paths must be valid
    if (is.null(local_context$path_cache_utility_1)) cli_abort("Error in composite_referential_integrity(): local_context$path_cache_utility_1 is NULL - please consider add a local cache path for this notebook.")
    if (is.null(local_context$path_cache_utility_2)) cli_abort("Error in composite_referential_integrity(): local_context$path_cache_utility_2 is NULL - please consider add a local cache path for this notebook.")
    if (!dir.exists(dirname(local_context$path_cache_utility_1))) cli_abort("Error in composite_referential_integrity(): local_context$path_cache_utility_1 directory fodler doesn't exist - please create a cache folder for this cache file.")
    if (!dir.exists(dirname(local_context$path_cache_utility_2))) cli_abort("Error in composite_referential_integrity(): local_context$path_cache_utility_2 directory fodler doesn't exist - please create a cache folder for this cache file.")
    unlink(local_context$path_cache_utility_1)
    unlink(local_context$path_cache_utility_2)
    
    ## Input validation: Must be dataframes or dataframe abstractions
    valid_object_1 = any(c('data.frame', 'ArrowObject') %in% class(df1)) 
    valid_object_2 = any(c('data.frame', 'ArrowObject') %in% class(df2)) 
    if (!valid_object_1 || !valid_object_2) {
      stop("Both inputs must be either dataframes or Arrow objects")
    }
    df1_class = ifelse('data.frame'%in%class(df1),'data.frame','ArrowObject')
    df2_class = ifelse('data.frame'%in%class(df2),'data.frame','ArrowObject')
  }
  
  # Test  ----------------------------------------------------------------
  {
    ## Small data ----------------------------------------------------------------
    { 
      if (data_scale == 'small'){
        
        ## Prep objects
        df1_distinct <- df1 %>% 
          select(all_of(vector_composite_keys)) %>%
          mutate(across(everything(), as.character)) %>%
          distinct() %>% 
          collect()
        
        df2_distinct <- df2 %>% 
          select(all_of(vector_composite_keys)) %>% 
          mutate(across(everything(), as.character)) %>%
          distinct() %>% 
          collect()
        
        ## Test
        df_inconsistent_rows <- bind_rows(
          anti_join(df1_distinct, df2_distinct, by = vector_composite_keys),
          anti_join(df2_distinct, df1_distinct, by = vector_composite_keys)
        )
        
        ## Result
        consistent = nrow(df_inconsistent_rows) == 0
        
      }
    }
    
    # Big data ----------------------------------------------------------------
    { 
      if (data_scale == 'big'){

        ### Cache parquet if needed
        if (df1_class == 'data.frame') {
          arrow::write_parquet(df1, local_context$path_cache_utility_1)
          df1_parquet = local_context$path_cache_utility_1
        } else {
          df1_parquet = df1$files
        }
        if (df2_class == 'data.frame') {
          arrow::write_parquet(df2, local_context$path_cache_utility_2)
          df2_parquet = local_context$path_cache_utility_2
        } else {
          df2_parquet = df2$files
        }
        
        ### Create Connection
        con <- dbConnect(duckdb::duckdb()) 
         

        ### Query (120 million rows per minute)
        df1_query = glue_sql("
                SELECT DISTINCT {`vector_composite_keys`*}
                FROM parquet_scan({df1_parquet})
                ORDER BY {`vector_composite_keys`*}
              ", .con = con)
        df2_query = glue_sql("
                SELECT DISTINCT {`vector_composite_keys`*}
                FROM parquet_scan({df2_parquet})
                ORDER BY {`vector_composite_keys`*}
              ", .con = con)
        if (nrow(df1) == nrow(df2)){
          ## Distinct Only if different number of rows
          df1_query = df1_query %>% str_remove_all("DISTINCT") %>% SQL()
          df2_query = df2_query %>% str_remove_all("DISTINCT") %>% SQL()
        }
        if ('observation_id' %in% vector_composite_keys){
          ## Sort only if metadata; (paritions or codebook manual edits hcange orders)
          ## do not sort if data (we assume obt is left joined on final data cube so order should be the same)
          remove_order_sql = glue_sql("
                ORDER BY {`vector_composite_keys`*}
              ", .con = con)
          df1_query = df1_query %>% str_remove_all(remove_order_sql) %>% SQL()
          df2_query = df2_query %>% str_remove_all(remove_order_sql) %>% SQL()
        }
      
        
        ## Execute (120 million rows per minute)
        df1_distinct <- dbGetQuery(con, df1_query)
        df2_distinct <- dbGetQuery(con, df2_query)
    
        ## Test
        df_inconsistent_rows <- bind_rows(
          anti_join(df1_distinct, df2_distinct, by = vector_composite_keys),
          anti_join(df2_distinct, df1_distinct, by = vector_composite_keys)
        ) 
        
        ## Result
        consistent = nrow(df_inconsistent_rows) == 0
        
        ### Reset
        unlink(local_context$path_cache_utility_1)
        unlink(local_context$path_cache_utility_2)
        dbDisconnect(con, shutdown = TRUE)
      }
    }
  }

  
  # Result ------------------------------------------------------------------
  
  if (!consistent)  {
    warning("Data points are not consistent as per composite_referential_integrity()")
    return(FALSE)
  }
  
  if (consistent) {
    return(TRUE)
  }
  
  
  
}