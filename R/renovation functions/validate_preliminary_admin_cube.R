

validate_preliminary_admin_cube = function(context){
  
  ## Validate
  staged_obt = context$path_cache_staged_obt %>% arrow::open_dataset()
  cli_alert_info("Start Full Referential Integrity Test between staged OBT and final data cube")
  validated_obt = staged_obt %>% 
    verify(full_referential_integrity(., context$final_data_cube, context)  ) %>%
    verify(valid_values_public(.))  
  
  ## Return
  cli_alert_success("Preliminary Admin Cube (Data + Metadata) validated!")
  return(T)
  
}
