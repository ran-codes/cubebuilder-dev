#' Sets up the data imports for a dataset ETL function
#'    - sync files: checks for
#' 


get_dataset_files = function(local_config, global_context){
  
  { # Setup -------------------------------------------------------------------
    
    ## local_config input validation
    c("observation_type_tmp", "dataset_id_tmp", "raw_dataset_dir", "version_tmp", 
      "date_tmp", "vec__var_names_to_remove", "dataset_instance_tmp", "env", 
      "file_list_tmp") %>% 
      walk(~{
        valid = all(  
          !is.na(local_config[.x]),
          !is.null(local_config[.x])
          )
        if (!valid) cli_abort("missing required local_config: {.x}")
      })
    
    ## Server Paths
    db_path = glue('{global_context$path_server_dmc}{local_config$raw_dataset_dir}')
    db_etl_path = glue("{db_path}_etl/")
    db_etl_version_path =  glue("{db_etl_path}{local_config$dataset_id_tmp}_{local_config$dataset_version_tmp}/")
    lock_file = glue("{db_etl_version_path}_source.csv")
    locked = file.exists(lock_file)
    if (!dir.exists(db_path)){
      cli_alert_danger("directory does not exist: {db_path}")
      stop("Incorrect directory")  }
    
   
    
    ## Objects
    dataset_san = local_config$dataset_id_tmp %>% sanitize_codebook_var()
    time_scale =  case_when(
      local_config$observation_type_tmp == 'record-level' ~ 'record',
      str_detect(str_to_lower(local_config$dataset_id_tmp),"month")~'month',
      str_detect(str_to_lower(local_config$dataset_id_tmp),"daily")~'daily',
      TRUE ~ 'year')
  }
  
  { # All files in server directory -------------------------------------------
    
    iso2_san_patterns = global_context$xwalk_iso2$iso2 %>% 
      map_chr(~glue("{local_config$dataset_id_tmp}{.x}") %>% 
                sanitize_codebook_var()) %>% 
      paste(collapse = '|') 
    
    
    if (is.null(local_config$file_list_tmp) ) df_files_all_template =  tibble(file = db_path %>% list.files())
    if (!is.null(local_config$file_list_tmp)) df_files_all_template = tibble(file = unlist(local_config$file_list_tmp))

    df_files_all = df_files_all_template %>% 
      filter(str_detect(file, '.csv')) %>% 
      rowwise() %>% 
      mutate(file_san = sanitize_codebook_var(file) %>% str_remove('.CSV'),
             dataset = local_config$dataset_id_tmp %>% sanitize_codebook_var(),
             file_clean = ifelse(
               any(str_detect(file_san, iso2_san_patterns)),
               str_sub(file_san,1L,-1L-2),
               file_san),
             file_base = str_remove_all(file, "\\d{8}"),
             path =  glue("{db_path}{file}"),
             size = file.info(path)$size) %>% 
      ungroup()
     
  }
  
  { # Subset for dataset ------------------------------------------------------
    
    if (dataset_san == "BEC") { ## Special case to migrate logic into BEC notebook
      
      df_files =  df_files_all %>% 
        filter(((file_clean == dataset_san) | (file_clean == "BECBACKCAST")),
               !((time_scale == "year")&(str_detect(file, 'MONTH'))),
               !((time_scale == "year")&(str_detect(file, 'DAILY'))),
               size >1000) %>% 
        rowwise() %>% 
        mutate(date =  get_date_from_data_file_name(file) %>% mdy() ) %>% 
        ungroup() %>% 
        group_by(file_base) %>% 
        filter(date == max(date)) %>% 
        ungroup() 
      df_files_to_process = df_files %>% filter(date <= mdy(date_tmp))
      
      
    } else if (local_config$observation_type_tmp == 'record-level') { ## This is the v2 datawarehous approach - assume files are explcityl defined in the `file_list_tmp` argument
     
      df_files_to_process =  df_files_all %>% 
        rowwise() %>% 
        mutate(date =  get_date_from_data_file_name(file) %>% mdy() ) %>% 
        ungroup()
      df_files = df_files_to_process ## Will deprecate this in future... not trying to be perfect. Can manual batch compare to previous _source. 
    } else { ## Legacy Logic to deprecate (if not standard file names then use `file_list_tmp` argument see BEC v2 or Health SUrvey notebooks for exmaples)
      
      df_files =  df_files_all %>% 
        filter(file_clean == dataset_san,
               !((time_scale == "year")&(str_detect(file, 'MONTH'))),
               !((time_scale == "year")&(str_detect(file, 'DAILY'))),
               size >1000) %>% 
        rowwise() %>% 
        mutate(date =  get_date_from_data_file_name(file) %>% mdy() ) %>% 
        ungroup() %>% 
        group_by(file_base) %>% 
        filter(date == max(date)) %>% 
        ungroup() 
      df_files_to_process = df_files %>% filter(date <= mdy(date_tmp)) 
      
    }
    
  }
  
  
  
  { # Return ------------------------------------------------------------------
    final = lst(
      df_files_to_process = df_files_to_process %>%
        mutate(
          etl_csv_path =  glue("{db_etl_version_path}{file}"),
          etl_parquet_path =  etl_csv_path %>% str_replace(".csv", ".parquet"),
        ),
      df_files = df_files
    )
    
    
    return(final)
  }
  
}
