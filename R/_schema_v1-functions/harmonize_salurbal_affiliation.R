crosslink_salurbal_affiliation = function(x, src__aff){
  
  xwalk_tmp = src__aff %>% filter(str_detect(x,aff_patterns))
  value_tmp = xwalk_tmp$aff_value %>% unique()
  if (nrow(xwalk_tmp)==0){
    # cli_alert_danger('No assocaited key for this affiliation!')
    return(list('TBD'))
  } else if (length(value_tmp)>1){
    # cli_alert_danger('More than one key assocaited!!')
    return(list(value_tmp))
  } else {
    # key_tmp = xwalk_tmp$aff_key
    # cli_alert_success('Linked `{value_tmp}` to `{x}`')
    return(list(value_tmp))
  }
  
}

harmonize_salurbal_affiliation = function(aff_raw_tmp, xwalk_aff_clean){
  
  # aff_raw_tmp = df_publications_stage %>% slice(2) %>% pull(aff) %>% .[[1]]
  
  aff_clean_tmp = aff_raw_tmp %>% 
    map(~xwalk_aff_clean %>% 
              filter(aff_raw == .x) %>% 
              pull(aff_clean)) %>% 
    unlist() %>% 
    unique()
  
  return(list(aff_clean_tmp))
}
