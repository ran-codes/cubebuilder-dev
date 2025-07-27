#' utility function for step 4 schema -> codebook template generation. This function will take in 
#' the final_data_cube, schema metadata, the specific metadata table and return a dataframe 
#' representation of the template
#' 
#' @param table_tmp: (string) label for the metadata table name. Acceptable values include `by_var`, `by_strata`, `by_var_year` ... etc
#' @param schema: (list) schema object imported from linkage.csv
#' @param context: (list) this is the dataset specific import object
#' 
#'     table_tmp = 'by_dataset'
#'     table_tmp = 'by_dataset_iso2'
#'     table_tmp = 'by_dataset_iso2_year'
#'     table_tmp = 'by_var'
#'     table_tmp = 'by_var_salid1'
#'     table_tmp = 'by_dataset_iso2_salid1'
#'     table_tmp = 'ddfsdaf'
#'     table_tmp = 'by_observation_id'

get_codebook_template = function(table_tmp, schema, context){
  
  { # Setup -------------------------------------------------------------------
    
    if(!table_tmp%in%schema$schema_tables){
      cli_alert_danger('table not in schema!')
      stop()
    }
    
    df__primary_keys =  context$xwalk_keys %>%  filter(table == table_tmp)
    primary_keys =  df__primary_keys %>% pull(keys)
    primary_keys_minus_raw  = df__primary_keys  %>%  filter(keys !='var_name_raw') %>%  pull(keys)
    columns = schema$schema_fields[table_tmp] %>% unlist() %>% unname() %>% remove_primary_keys()
    is__by_var_linkage = str_detect(table_tmp,'by_var')
    is__by_salid1_linkage = str_detect(table_tmp,'salid1')
    
    }
  
  
  { # Return template ------------------------------------------------------------------
    if (table_tmp == 'by_observation_id') {
      template = context$df__observation_id_with_metadata %>% 
        left_join(context$xwalk_area_level_observation_id_labels %>% select(-observation_pid)) %>% 
        mutate(!!!setNames(rep(NA, length(columns)),columns)) %>% 
        mutate_all(~as.character(.x)) %>% 
        mutate_all(~replace_na(.x, replace = ''))
    } else if (!is__by_var_linkage){
      template = context$metadata_cube_key_template %>% 
        select(all_of(primary_keys_minus_raw)) %>% 
        distinct()  %>%
        collect() %>% 
        mutate(!!!setNames(rep(NA, length(columns)),columns)) %>% 
        mutate_all(~as.character(.x)) %>% 
        mutate_all(~replace_na(.x, replace = ''))
    } else {
      template = context$final_data_cube  %>%
        select(all_of(primary_keys_minus_raw), var_name_raw) %>% 
        distinct() %>% 
        collect() %>% 
        group_by(across(all_of(primary_keys_minus_raw))) %>% 
        summarize(var_name_raw = pack_string(var_name_raw)) %>%
        arrange(!!!syms(primary_keys)) %>% 
        mutate(!!!setNames(rep(NA, length(columns)),columns)) %>% 
        select(var_name, var_name_raw, any_of(primary_keys_minus_raw), everything()) %>% 
        mutate_all(~as.character(.x)) %>% 
        mutate_all(~replace_na(.x, replace = ''))
    }
  
    
    ## Arrange before return
    column_order = names(template) %>% keep(~.x%in%primary_keys_minus_raw)
    template = template %>%
      arrange(across(all_of(column_order)))
    return(template)
  }
  
}
