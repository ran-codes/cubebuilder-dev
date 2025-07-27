##' There are some data composite keys that require non missing values (but this is conditional on observation_type). 
##' All require: dataset_instance, version, dataset_id, observation_type, observation_id, var_name, var_name, raw
##' Area level require: geo, year, iso2,
##' Some that are missing is okay
##'    - day, month, strata_id
##'    
##' Note:
##'    - we temperaorily quarnetine CI_validation (the code is archived below. don't delete for now)
##'       - we will need to figuoure out how to pass thsi into downstream vlaidatioan wihtou updateing context   
##'    
##'    Examples
##'        df_data_int = arrow::open_dataset(local_context$path_cache_int_data)

validate_final_admin_data_cube <- function(df_data_int, local_context) {

  ## Validation (pace ~ 40 million rows per minute)
  final_data_cube = df_data_int %>%
    ## Composite key Integrity
    verify(composite_key_integrity(., local_context, cube_type = 'data')) %>% 
    verify(composite_key_uniqueness(., local_context)) %>% 
    ## All Columns
    verify(valid_column_names(., local_context, cube_type = 'data')) %>% 
    ## Renovations
    verify(valid_utf8_df(.)) %>%
    verify(valid_salid_geo(.)) %>% 
    verify(valid_unpacking(.)) 

  ## Return
  cli_alert_success(glue("Integrated test passed: validate_final_admin_data_cube()!"))
  return(final_data_cube)
}


## Verify
# verify(successful_import_of_ci_attributes(., local_context)) %>% ## Quarentine for now will get to updating CI stuff for v2 when we get there


## Update local context - Add a flag for confidence intervals ## Quarentine for now will get to updating CI stuff for v2 when we get there
# dataset_has_ci = c('value_uci','value_lci')%in%names(validated_data_cube) %>% all()
# vec__var_ci = NULL
# if (dataset_has_ci){
#   vec__var_ci = validated_data_cube %>% 
#     group_by(var_name) %>% 
#     filter(value_uci!=''&value_lci!='') %>% 
#     ungroup() %>% 
#     arrange(var_name) %>% 
#     pull(var_name) %>% 
#     unique()  }
# local_context$vec__var_ci = vec__var_ci