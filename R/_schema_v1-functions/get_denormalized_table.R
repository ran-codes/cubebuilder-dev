#' Compiled denomralized table
#' 
#' 
#'  @param etl_status should be a data frame with paths generated from  get_elt_status(return_path = T)
#'  @param internal indicator for whether the table should be for internal use. If `internal`==True then
#'                  the returned table will include all the SALURBAL data including non-public data points.
#'                  If `internal` == False (default), then the table will return publicly available data points. 
#' 
#' internal = F; etl_status = get_elt_status(return_path = T); .x = etl_status %>% slice(1) %>% pull(path_denormalized)
#'  
#'  

source_parent('get_server_path')


get_denormalized_table = function(etl_status, internal = F){
  
  # Stage
  stg_path = etl_status$path %>% 
    select(dataset_id, path_denormalized) %>% 
    drop_na() %>% 
    distinct()
  
  
  # Intermediate
  int_denormalized = stg_path$path_denormalized %>% 
    map_df(~{return(arrow::read_parquet(.x))})

  # Final
  if (internal) {
    ## If internal then return every data point
    df_final = int_denormalized
  } else if (!internal){
    ## If not internal aka public then return only public data points
    df_final = int_denormalized %>% filter(public == '1')
  }
  return(df_final) 
}
