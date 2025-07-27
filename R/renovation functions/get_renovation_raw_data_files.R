#' DEPRECATE in v2 after validatio ( we completely removed autoamtic file 
#' detection, going to do datasets epcific rpogramic or mnual list of files to freeze)


get_renovation_raw_data_files = function(local_config, global_context, paths){
  
  # { # Setup -------------------------------------------------------------------
  #   
  #   ## Input validation: Check local_config has all required information
  #   c("observation_type_tmp", "dataset_id_tmp", "raw_dataset_dir", "version_tmp", 
  #     "date_tmp",  "dataset_instance_tmp",  "file_list_tmp",
  #     "vec__var_names_to_remove"
  #     ) %>% 
  #     walk(~{
  #       valid = all(  
  #         !is.na(local_config[.x]),
  #         !is.null(local_config[.x]),
  #         ifelse(.x == 'vec__var_names_to_remove', TRUE, local_config[.x] != '')
  #         )
  #       if (!valid) cli_abort("Local_config invalid: empty or missing required field - `{.x}`")
  #     })
  #   
  #   ## Input validation: Required Server Paths exist
  #   if (!dir.exists(paths$dataset_instance_freeze_path)){
  #     cli_alert_danger("directory does not exist: {paths$dataset_instance_freeze_path}")
  #     stop("Incorrect directory")  
  #     }
  #   
  #  
  #   
  #   ## Objects
  #   dataset_san = local_config$dataset_id_tmp %>% sanitize_codebook_var()
  #   time_scale =  case_when(
  #     local_config$observation_type_tmp == 'record-level' ~ 'record',
  #     str_detect(str_to_lower(local_config$dataset_id_tmp),"month")~'month',
  #     str_detect(str_to_lower(local_config$dataset_id_tmp),"daily")~'daily',
  #     TRUE ~ 'year')
  # }
  # 
  # { # All files in server directory -------------------------------------------
  #   
  #   iso2_san_patterns = global_context$xwalk_iso2$iso2 %>% 
  #     map_chr(~glue("{local_config$dataset_id_tmp}{.x}") %>% 
  #               sanitize_codebook_var()) %>% 
  #     paste(collapse = '|') 
  #   
  #   
  #   if (is.null(local_config$file_list_tmp) ) df_files_all_template =  tibble(file = db_path %>% list.files())
  #   if (!is.null(local_config$file_list_tmp)) df_files_all_template = tibble(file = unlist(local_config$file_list_tmp))
  # 
  #   df_files_all = df_files_all_template %>% 
  #     filter(str_detect(file, '.csv')) %>% 
  #     rowwise() %>% 
  #     mutate(file_san = sanitize_codebook_var(file) %>% str_remove('.CSV'),
  #            dataset = local_config$dataset_id_tmp %>% sanitize_codebook_var(),
  #            file_clean = ifelse(
  #              any(str_detect(file_san, iso2_san_patterns)),
  #              str_sub(file_san,1L,-1L-2),
  #              file_san),
  #            file_base = str_remove_all(file, "\\d{8}"),
  #            path =  glue("{db_path}{file}"),
  #            size = file.info(path)$size) %>% 
  #     ungroup()
  #    
  # }
  # 
  # { # Subset for dataset ------------------------------------------------------
  #   
  #   
  #   df_files_to_process =  df_files_all %>% 
  #     rowwise() %>% 
  #     mutate(date =  get_date_from_data_file_name(file) %>% mdy() ) %>% 
  #     ungroup() %>%
  #     mutate(
  #       etl_csv_path =  glue("{db_etl_version_path}{file}"),
  #       etl_parquet_path =  etl_csv_path %>% str_replace(".csv", ".parquet"),
  #     )
  #   
  #   
  # }
  # 
  # 
  # 
  # { # Return ------------------------------------------------------------------
  #  
  #   return(df_files_to_process)
  # }
  
  return(NULL)
}
