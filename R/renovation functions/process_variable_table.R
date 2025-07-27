#' Validates and exports step 1: var_name.csv. Tests include:
#'    - `valid_utf8`: checks all tables are utf8 encoded
#'    - `valid_non_dataset_variables`: check that each dataset's variable list (df_var_name) does not include
#'                                     project level variables including:
#'                                          - INCLUDE_NOBDRYCHG_L1AD 
#'                                          - INCLUDE_NOUNITCHG_L1AD 
#'    - `valid_data_var_names`: checks that each dataset's df_var_name does not include
#'                                primary keys or metadatafound in raw_data. Explicity checks for:
#'                                          - all primary keys
#'                                          - file_data
#'    - `valid_unique_identifier`: checks that var_name is unique and not already regiestered within SALURBAL.
#'                                          
#'                          
#'                                          

source_parent('validate_df_utf8') 


process_variable_table = function(df_var_name, context){
  
  { # Setup -------------------------------------------------------------------
    cli_alert_info( style_bold("Step 1 (Variable list)"))
  }
  
  { # Validation ------------------------------------------------------------
    
    { ## `valid_utf8` -------------------------------------------------------------
      valid_utf8 = validate_df_utf8(df_var_name)
    }
    
    { ## `valid_non_dataset_variables` -------------------------------------------
      proj_level_var_name = c('INCLUDE_NOBDRYCHG_L1AD','INCLUDE_NOUNITCHG_L1AD') %>% map_chr(~ sanitize_codebook_var(.x))
      df_invalid = df_var_name %>% filter(var_name%in%proj_level_var_name)
      valid_non_dataset_variables = nrow(df_invalid)==0
      if (!valid_non_dataset_variables){
       cli_alert_danger('valid_non_dataset_variables ERROR: some prj level variables in df_var_name')
        df_invalid$var_name_raw %>% walk(~cli_alert_danger('-{.x}'))
      }
    }
    
    { ## `valid_non_primary_keys` -------------------------------------------------------------
      non_var_names = c(context$xwalk_keys %>% pull(keys) %>% unique(),'filedata') %>% str_to_upper()
      invalid_var_names = str_to_upper(df_var_name$var_name) %>% keep(~.x%in%non_var_names)
      valid_non_primary_keys = length(invalid_var_names) == 0
      if (!valid_non_primary_keys){
        cli_alert_danger('valid_non_primary_keys ERROR: some invalid var_name in df_var_name')
        invalid_var_names %>% walk(~cli_alert('{.x}'))
      }
    }
    
    
    { ## valid_unique_identifier -------------------------------------------------
      ## So this test will check if proposed var_name is does not exist in other datasets
      vec__proposed_var_names =  df_var_name %>%  pull(var_name)
      api_metadata = context$path_server_api_metata %>% arrow::open_dataset()
      vec__existing_var_names = api_metadata %>% 
        filter(dataset_id != context$dataset_id_tmp)%>% 
        count(var_name) %>% 
        collect()  %>%
        pull(var_name)
      non_unique_var_name = vec__proposed_var_names %>% keep(~.x%in%vec__existing_var_names)
      valid_unique_identifier = length(non_unique_var_name) == 0
      if (!valid_unique_identifier){
        cli_alert_danger('valid_unique_identifier ERROR: some  var_name are not unique within SALURBAL.')
        invalid_var_names %>% walk(~cli_alert('{.x}'))
      }
      
    }
    { ## compile -------------------------------------------------------------
      valid_step = all(valid_utf8, valid_non_dataset_variables, valid_non_primary_keys, non_unique_var_name)
    }
  }
  
  { # Export ------------------------------------------------------------------
    if (!valid_step) { 
      cli_alert_danger("INVALID STEP 1: df_var_name invalid") 
      stop()  
    } else {
      
      { # Assertion tests ------------------------------------------------------------------
        
        validated_df_var_name = df_var_name  %>%
          verify(has_only_names(context$vec__admin_variable_definition_table_columns)) %>% 
          assert(is_uniq, var_name_raw) %>%
          arrange(var_name, var_name_raw) %>% 
          pack_string_column('var_name_raw') 
        
      }
      
      { # Write ------------------------------------------------------------------
        
        ## Casual visibility
        validated_df_var_name  %>% fwrite(context$path_variable_csv)
        
        ## Standard storage format
        validated_df_var_name  %>% arrow::write_parquet(context$path_variable_parquet)
        
        ## Version control diff
        validated_df_var_name %>% write_json(context$path_variable_json, pretty = TRUE, auto_unbox = TRUE)
        
      } 
      
      
      { # Log ------------------------------------------------------------------
        cli_alert("df_var_name validated")
        cli_alert(glue("Wrote variable table for {context$dataset_instance_tmp}"))
        cli_alert_success(paste("Success"))
      }
    }
  }
}



