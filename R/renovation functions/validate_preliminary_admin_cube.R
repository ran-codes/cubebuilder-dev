

validate_preliminary_admin_cube = function(local_context){
  
  ## Validate
  staged_obt = local_context$path_cache_staged_obt %>% arrow::open_dataset()
  cli_alert_info("Start Full Referential Integrity Test between staged OBT and final data cube")
  validated_obt = staged_obt %>% 
    verify(full_referential_integrity(., local_context$final_data_cube, local_context)  ) %>%
    verify(valid_values_public(.))  
  
  ## Return
  cli_alert_success("Preliminary Admin Cube (Data + Metadata) validated!")
  return(T)
  
}
