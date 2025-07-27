#' Validates the linkage.csv then exports schema.png if valid. This only runs if 
#' dataset_status has already passed the `linkage` cycle is already passed/TRUE.
#' 
#' Tests for
#'    - `valid_utf8`: checks all tables are utf8 encoded
#'    - `valid_follows_template`: checks that linkage.csv has the exact same fields as the linkage template
#'    - `valid_values`: checks that all fields are designated to at least one relationship/sheet
#'    - `valid_linkage`: checks that each field only has a single type of linkage.
#'    


source_parent('validate_df_utf8') 


process_linkage_table = function(local_context){
  
  { # Setup -------------------------------------------------------------------
    
  
    ## Input Validation: Requires linkage.csv
    fail = !file.exists("3-linkage.csv")
    if (fail) cli_abort("process_linkage_table() Input validation failed: linkage.csv not found. Please make sure you have a linkage.csv that specifies how metadata should be linked via composite keys before running process_linkage_table().")
    if (!fail){
      df_linkage_raw = read_csv("3-linkage.csv", show_col_types = F)
      vec__composite_key_configs = names(df_linkage_raw) %>% discard(~.x == 'field')
    }
    
    ## Input Validation: composite key specification should never be by_dataset_... and something else
    fail = any(vec__composite_key_configs %>% str_detect("_dataset_"))
    if (fail) cli_abort("process_linkage_table() Input validation failed: dataset composite key configurations should be minimal and only by_dataset. Everything else is assumed to be by_dataset. E.g. please recode your `by_dataset_var` to `by_var` or `by_dataset_iso2` to just `by_iso2`")
    
    ## Input validation: Observation_id level metadta should only apply to area-level records
    fail = 'by_observation_id'%in%vec__composite_key_configs & local_context$observation_type_tmp != 'area-level'
    if (fail) cli_abort("process_linkage_table() Input validation failed: Observation_id level metadata is configured but this is only allowed for `area-level` observation_types of data. Please check your configurations.")
  }
  
  
  { # Import linkage.csv ------------------------------------------------------
    schema = lst(
      has_schema = T,
      df_schema = df_linkage_raw %>% 
        mutate(field = field %>% str_remove_all('\t')) %>% 
        select_if(~sum(!is.na(.)) > 0) %>% 
        as_tibble(),
      df_schema_tidy = df_schema %>% 
        pivot_longer(-field, names_to = 'table') %>% 
        drop_na() %>% 
        select(table,
               column = field) %>% 
        arrange(table) ,
      # schema_tables = unique(df_schema_tidy$table) %>% sort(),
      schema_tables = df_schema %>% 
        select(-field) %>% 
        select(sort(setdiff(names(.), "by_observation_id")), any_of("by_observation_id")) %>% 
        names(),
      schema_fields = schema_tables%>% 
        map(~ get_table_columns_from_schema(.x,df_schema_tidy, local_context$xwalk_keys)) %>% 
        set_names(schema_tables)
    ) 
  }
  
  { # Validation ------------------------------------------------------------
    
    {  # `valid_df_observation_id` -------------------------------------------------------------
      ## Input Validation: If linkage.csv specifies observation_id level metadata then `df__observation_id_with_metadata` must exist in local context
      metadata_by_observation_id = 'by_observation_id'%in%names(read_csv("3-linkage.csv", show_col_types = F))
      if (metadata_by_observation_id & is.null(local_context$df__observation_id_with_metadata)){
        cli_abort("process_linkage_table() Input validation failed: linkage.csv specifies metadata by observation_id but `df__observation_id_with_metadata` is not in local context. Please make sure you have a df__observation_id_with_metadata in local context before running process_linkage_table().")
      }
    }
    
    {  # `valid_utf8` -------------------------------------------------------------
      valid_utf8 = validate_df_utf8(schema$df_schema)
      if (!valid_utf8) cli_abort("valid_utf8 ERROR: invalid encoding. please check.")
    }
    
    { # `valid_follows_template` -------------------------------------------------------------
      schema_fields  = schema$df_schema %>% pull(field) 
      template_fields = local_context$template__linkage %>% pull(field) 
      
      extra_fields = setdiff(schema_fields,template_fields)
      missing_fields = setdiff(template_fields,schema_fields)
      
      valid_follows_template = length(c(extra_fields, missing_fields))==0
      if (!valid_follows_template){
        if (length(extra_fields)>0) cli_alert_danger(glue("- Extra columns: {paste(extra_fields,collapse = ',' )}"))
        if (length(missing_fields)>0)cli_alert_danger(glue("- Missing columns: {paste(missing_fields,collapse = ',' )}"))
        cli_abort(glue("valid_follows_template ERROR: linkage.csv does not adhere to 3-linkage_template.csv"))
      }
    }
    
    { # `valid_linkage` ------------------------------------------------------
      # Only run for non-hierachical lnkages (most of the cases) (legacy)
      # v2 - only run for non-by_observation_id linkages
      if (is.null(local_context$df__observation_id_with_metadata)){
        df_linkage_count = schema$df_schema_tidy %>% 
          count(column) %>% 
          filter(n > 1) 
        valid_linkage = nrow(df_linkage_count) == 0
        if (!valid_linkage ) {cli_abort("valid_linkage ERROR: some columns in linkage.csv have multiple linkage types.")}
      }
    } 
    
    { # `valid_values` ------------------------------------------------------
      if (is.null(local_context$df__observation_id_with_metadata)){
        df_invalid_values =    schema$df_schema  %>% 
          pivot_longer(-field, names_to = 'table') %>% 
          group_by(field) %>% 
          summarize(n_value = sum(value, na.rm = T)) %>% 
          filter(n_value != 1)
        
        valid_values = nrow(df_invalid_values)==0
        if (!valid_values) {
          df_invalid_values$field %>% walk(~cli_alert("{.x} is missing a linkage"))
          cli_abort("valid_linkage ERROR: some fields in linkage.csv are missing relationship desgnations.")
        }
      }
    }
    
    # { # valid_complex_linkage_info -------------------------------------------------
    #   DEPRECATE: FOr LE_POSTAMP Medta link use obeeservation_id not custom salid1
    #   # if flagged as hierarchical linkage then must have which sheets
    #   missing_hierachical_linkage_details = length(local_context$hierachical_linkage_sheets) == 0
    #   if (local_context$is__hierarchical_linkages & missing_hierachical_linkage_details) {
    #     cli_abort('valid_salid1_in_df_data ERROR: salid1 is a key in linkages but not present in data! Please add salid1 into data see LE_POSTAMP as example.')
    #   }
    # }
    
    
  }
  
  
  { #  Template -------------------------------------------------------------
    
    { ## Update status ------------------------------------------------------------------
      cli_alert("Valid linkage.csv")
      if (!is.null(local_context$df__observation_id_with_metadata)){
        cat_bullet("Metadata by `observation_id` detected")
      }
    }
    
    { ## Write schema -------------------------------------------------------------
      # draw_schema_from_linkage(schema$df_schema_tidy, dataset_id_tmp, local_context)
    }
    
    { ## Write codebook templates -----------------------------------------------
      
      ## Generate template sheets
      template_sheets = schema$schema_tables %>%
        map(~get_codebook_template(.x, schema, local_context)) %>% 
        set_names(schema$schema_tables)
      
      ## Write .xlsx
      if (!identical_cdbk_vs_xslx(template_sheets,local_context$template_cdbk_path, local_context)){
        wb = createWorkbook()
        cs_text_bold <- CellStyle(wb) +  Font(wb, isBold=TRUE)
        map(names(template_sheets),
            function(sheet_name){
              sheet =  createSheet(wb, sheetName = sheet_name)
              addDataFrame(as.data.frame(template_sheets[[sheet_name]]),
                           sheet,
                           colnamesStyle = cs_text_bold,
                           row.names = F)  })
        saveWorkbook(wb,local_context$template_cdbk_path)
        cli_alert(glue("Generate __codebook.xslx template for {local_context$dataset_id_tmp}" ))
        if (!file.exists(local_context$raw_cdbk_path)) file.copy(local_context$template_cdbk_path,local_context$raw_cdbk_path)
        
      }
      
    }
    
    { # Snapshot   -----------------------------------------------
      cli_alert_success("Shema validated and template generated!")
      snapshot_excel(path = local_context$template_cdbk_path)
      snapshot_excel(path = local_context$raw_cdbk_path)
    }
  } 
  
  { # Template Metadata Cube -----------------------------------------------------------
    
    ## Generate Cube
    templates = import_salurbal_xslx_cdbk(local_context$template_cdbk_path, local_context)
    template_metadata_cube = denormalize_codebook_object(
      codebook_object = templates, 
      local_context, 
      template = T,
      raw = F)
     
    ## Cache Metadata
    template_metadata_cube %>% arrow::write_parquet(local_context$path_cache_metadata_cube_template)
  }
 
  
  {# Return ------------------------------------------------------------------
    cli_alert_success("Linkage.csv validated and templates + template-metadata-cubes cached!")
    cli_alert_info("Please refresh local context to bring these into local context object.")
    return(template_metadata_cube)
  }
}

