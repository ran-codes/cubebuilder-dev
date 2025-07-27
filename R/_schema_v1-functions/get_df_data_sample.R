#' returns a subset of df_data for validatioan
#' 


get_df_data_sample = function(df_data){
  df_data %>% 
    group_by(dataset_id, file_data,
             var_name,iso2, strata_id,
             geo,year)%>% 
    slice(1) %>% 
    ungroup() %>% 
    return()
}