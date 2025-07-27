#' Validates the strata.csv then exports if valid. Tests for
#'    - `valid_utf8`: checks all tables are utf8 encoded
#'    - `valid_null`  : checks that if no strata_id then
#'                       - missing all strata information.
#'    - `valid_strata_1`: checks if single strata then all the following fields have values
#'                       - `strata_id` 
#'                       - `strata_1_name`
#'                       - `strata_1_value`
#'                       - `strata_1_raw` has a value unless strata_1_name is Sex and strata_1_value is Overall
#'    - `valid_strata_2`: checks that strata.csv
#'    - `valid_chr_type`: checks that all columsn are character


source_parent('validate_df_utf8') 


process_strata_table = function(df_strata, local_context){
  
  
  
  { # Setup -----------------------------------------------------
    
    cli_alert_info( style_bold("Step 2 (Strata metadata)"))
    
    df_strata_long  = df_strata %>% 
      mutate_all(~as.character(.x)) %>% 
      pivot_longer(cols = -c(any_of(local_context$vec__admin_composite_keys_all),
                             var_name_raw)) 
    df_strata_summary = df_strata_long  %>%
      group_by(var_name, var_name_raw) %>% 
      summarize(n_values = sum(value != ''),
                .groups = 'drop') %>% 
      ungroup() %>% 
      arrange(desc(n_values))
    int_vec_null = df_strata_summary %>% filter(n_values == 0) %>% pull(var_name_raw)
    int_vec_single = df_strata_summary %>% filter(between(n_values,1,4)) %>% pull(var_name_raw)
    int_vec_double = df_strata_summary %>% filter(between(n_values,5,7)) %>% pull(var_name_raw)
  }
  
  { # Validation ------------------------------------------------------------
    
    
    { ## `valid_strataid_schema-v2_standards` -------------------------------------------------------------
      df_invalid = df_strata %>% 
        filter(str_detect(strata_id, 'NA_NA'))
      if (nrow(df_invalid) > 0 ) cli_abort("Error in process__strata_table(): found '_NA' pattern in strata_id. Please remove.")
    }
    
    { ## `valid_utf8` -------------------------------------------------------------
      valid_utf8 = validate_df_utf8(df_strata)
    }    
    
    { ## `valid_null`` --------------------------------------------------------------
      valid_null = df_strata_long %>% 
        filter(var_name_raw %in% int_vec_null) %>% 
        mutate(valid_value = value == "") %>% 
        pull(valid_value) %>% 
        all()
      if (!valid_null){cli_alert_danger(glue('`valid_null` error: strata_id is missing but some strata info present.'))}
    }
    
    { ## `valid_strata_1`` --------------------------------------------------------------
      valid_single = df_strata %>% 
        filter(var_name_raw %in% int_vec_single) %>% 
        mutate(valid_value = all(
          strata_id != '',
          strata_1_name != '',
          strata_1_value != '',
          (strata_1_raw != '')|(strata_1_name == "Sex" & strata_1_value == "Overall" )
        )) %>% 
        pull(valid_value) %>% 
        all()
      if (!valid_single){cli_alert_danger(glue('`valid_strata_1` error: Missing strata 1 information!'))}
    }
    
    { ## `valid_strata_2`` --------------------------------------------------------------
      valid_double = df_strata %>% 
        filter(var_name_raw %in% int_vec_double) %>% 
        mutate(valid_value = all(
          strata_id != '',
          strata_2_name != '',
          strata_2_value != '',
          (strata_2_raw != '')|(strata_1_name == "Sex" & strata_1_value == "Overall" )
        )) %>% 
        pull(valid_value) %>% 
        all()
      if (!valid_double){cli_alert_danger(glue('`valid_strata_2` error: Missing strata 2 information!'))}
      
    }
    
    { ## `valid_chr_type --------------------------------------------------------------
      chr_columns = df_strata %>% select_if(is.character) %>% names() 
      valid_chr_type = ncol(df_strata) == length(chr_columns)
      if (!valid_chr_type){
        num_columns = df_strata %>% select_if(is.numeric) %>% names() 
        bool_columns = df_strata %>% select_if(is.logical) %>% names() 
        cli_alert_danger(glue("`valid_chr_type` error: {paste(c(num_columns,bool_columns), collapse = ', ')} are not character"))
      }
    }
    
    { ## compile -------------------------------------------------------------
      valid_step = all(c(valid_utf8, valid_null,valid_single,valid_double))
    }
  }
  
  
  # Export -------------------------------------------------------------
  if (!valid_step) { 
    cli_alert_danger("INVALID STEP 2: df_strata invalid") 
    stop()  
  } else {
    
    { # Assertion Testing -------------------------------------------------------
      
      validated_df_strata = df_strata %>% 
        verify(has_all_character_column_types(.)) %>% 
        verify(has_columns(
          .,
          list(local_context$vec__admin_strata_definition_table_columns),
          message = 'all strata table columns'))  %>%
        verify(columns_must_not_have_NA_NULL_cells(
          .,
          list(names(df_strata)),
          message = 'all strata table columns')) %>% 
        verify(columns_must_not_have_EMPTY_cells(
          .,
          list(c('dataset_id','dataset_version','dataset_instance','schema_version','var_name','var_name_raw')),
          message = 'all strata table composite keys')) %>% 
        arrange(var_name, var_name_raw)
    }
    
    { # Write ------------------------------------------------------------------
      
      ## Casual visibility
      validated_df_strata  %>% fwrite(local_context$path_strata_csv)
      
      ## Standard storage format
      validated_df_strata  %>% arrow::write_parquet(local_context$path_strata_parquet)
      
      ## Version control diff
      validated_df_strata %>% write_json(local_context$path_strata_json, pretty = TRUE, auto_unbox = TRUE)
       
    } 
    
    { # Log ------------------------------------------------------------------
      cli_alert("df_strata validated.")
      cli_alert(glue("Wrote strata.csv for {local_context$dataset_id_tmp}"))
      cli_alert_success(paste("Success"))
    }
  } 
}

