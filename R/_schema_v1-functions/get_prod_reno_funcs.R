#' get production (minus purgator renovation funs) as a name list. 
#' 


prep_prod_reno_funcs = function(etl, purgatory = '', dataset_id_only = F){
  
  pergatory_funcs = glue('etl_safely_{purgatory}')
  prod_funcs_raw = etl$etl_functions %>% 
    discard(~.x%in%pergatory_funcs)
  
  ## If multiple versions keep only most recent
  df_prod_func_unique =  tibble(
    raw_func = prod_funcs_raw
  ) %>% 
    mutate(
      int_str = str_remove(raw_func,'etl_safely_')
    ) %>% 
    rowwise() %>% 
    mutate(version = str_split(int_str,"_") %>% unlist() %>% tail(n=1),
           version_num = parse_number(version),
           dataset_id = str_remove(int_str,glue("_{version}"))) %>% 
    ungroup() %>% 
    group_by(dataset_id) %>% 
    filter(version == max(version)) %>% 
    ungroup()
  
  vec__prod_funcs = df_prod_func_unique$raw_func
  
  if (!dataset_id_only){
    final = as.list(vec__prod_funcs) %>% 
      set_names(vec__prod_funcs)
    return(final)
  }
  
  if (dataset_id_only){
    vec__prod_funcs %>% 
      str_remove("etl_safely_") %>% 
      return()
  }
    
}
