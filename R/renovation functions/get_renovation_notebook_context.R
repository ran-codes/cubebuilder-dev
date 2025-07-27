#' Setup ETL and imports seeds for dataset specific renovation
#'    - ETL Init: sets up etl folders 
#'    - ETL backup: if not backed up in etl/version/ then backup as historical storage
#'    - Import raw_data: Imports data from historical backup 
#'    - Dataset object: 
#' 

source_parent('get_server_path')
source_parent('get_gh_path')
source_parent('get_renovation_raw_data_files')


get_renovation_notebook_context = function(local_config, global_context){

 
  { # Setup -------------------------------------------------------------------
    
    
    { # Local Config validation --------------------------------------------------------
        
      ## Local configurations must contain require information
      vec__required_local_configs = c(
        ## Composite keys (Required)
        'dataset_id_tmp','dataset_version_tmp','observation_type_tmp','schema_version_tmp',
        ## Processing info (Required)
        'raw_dataset_dir','vec__var_names_to_remove','file_list_tmp',
        ## Renovation metadata (Required)
        'dataset_renovation_maintainer','dataset_renovation_context_contributor'
      ) 
      
      vec__required_local_configs %>% 
        walk(~{
          if (is.null(local_config[[.x]])) cli_abort("Required local configuration `{.x}` is missing required configuration. Please enter valid value for `{.x}` and try setup again.")
        })
      
      ## Check correct directory
      if (!str_detect(getwd(), local_config$dataset_id_tmp)) cli_abort("Current directory is not in the right place. Please set the working directory to the current dataset directory for this dataset - `{local_config$dataset_id_tmp}_{local_config$dataset_version_tmp}`.")
      
    }
    
    { # Freeze paths -------------------------------------------------------------
      
      local_paths = lst(
        dataset_freeze_path = file.path(global_context$path_server_etl_freeze, local_config$dataset_id_tmp),
        dataset_instance_freeze_id = glue("{local_config$dataset_id_tmp}_{local_config$dataset_version_tmp}-schema-{local_config$schema_version}"),
        dataset_instance_freeze_path = file.path(dataset_freeze_path, dataset_instance_freeze_id),
        frozen_compiled_raw_data = file.path(dataset_instance_freeze_path, "_frozen_raw_data.parquet"),
        lock_file_name = '_lock.json',
        server_lock_file = file.path(dataset_instance_freeze_path, lock_file_name),
        repo_lock_file = '_lock.json',
        repo_lock_file_parquet = '_lock.parquet'
      )
      
    }

    
    { # Initialize freeze folders ------------------------------------------------------

      if (!dir.exists(local_paths$dataset_freeze_path)) {
        dir.create(local_paths$dataset_freeze_path, recursive = TRUE)
        cli_alert_success("Created Server Freeze directory `{local_paths$dataset_freeze_path}`")
      } 
      if (!dir.exists(local_paths$dataset_instance_freeze_path)) {
        dir.create(local_paths$dataset_instance_freeze_path, recursive = TRUE)
        cli_alert_success("Created Server Freeze Instance directory `{local_paths$dataset_instance_freeze_path}`")
      }     
      
    }
    
  }
  
  { # Lock file --------------------------------------------------------
    # Note: a lock file is just metadata on what files are being frozen for this dataset
     
    ## Import if locked
    locked = file.exists(local_paths$repo_lock_file_parquet)
    if (locked) df_lock = local_paths$repo_lock_file_parquet  %>% 
      arrow::read_parquet()
      
    ## Lock if not locked
    if (!locked) {
      ## Local Configuration input validation
      # local_raw_data_files = get_renovation_raw_data_files(local_config, global_context, paths) 
      
      df_lock = tibble(file = local_config$file_list_tmp %>% unlist()) %>% 
        arrange(file) %>%
        mutate(
          path = file.path(local_paths$raw_dataset_dir, file),
          size = file.info(path)$size,
          size_mb = size / 10 ^ 6,
          file_name = str_remove(file, '.csv'),
          freeze_parquet_path = file.path(local_paths$dataset_instance_freeze_path,
                                          glue("{file_name}.parquet") )
          )

      df_lock %>%  write_json(local_paths$server_lock_file, pretty = T)
      df_lock %>%  arrow::write_parquet(local_paths$repo_lock_file_parquet)
      df_lock %>%  write_json(local_paths$repo_lock_file, pretty = T)
      locked = T
      cli_alert_success("Created lock file  {local_config$dataset_id_tmp}_{local_config$dataset_version_tmp}")
    }

  }
  
  { # Raw data -------------------------------------------

    ## Freezing ----------------------------------------------------------------
    {

      ## Get unfrozen files
      frozen_files = list.files(local_paths$dataset_instance_freeze_path) %>% 
        discard(~.x=='raw_data.parquet')%>% 
        discard(~.x=='_lock.json') %>% 
        str_remove(".parquet")
      if (length(frozen_files)==0){
        freeze_complete = F
        df_unfrozen_files = df_lock
      }
      if  (length(frozen_files)>0 ){
        df_unfrozen_files = df_lock %>% filter(!file_name %in%frozen_files) 
        freeze_complete = nrow(df_unfrozen_files) == 0
      }
      if (freeze_complete) cli_alert_success("{local_config$dataset_id_tmp}_{local_config$dataset_version_tmp} data already frozen.")
      
      ## Freeze unfrozen files
      if (!freeze_complete){
        df_unfrozen_files %>%
          group_by(row_number()) %>%
          group_walk( ~ {
            row = .x 
            if (!file.exists(row$freeze_parquet_path)) {
              row$path %>%
                read_csv() %>%
                arrow::write_parquet(sink = row$freeze_parquet_path)
              cli_alert_success("etl parquet backup {row$file %>% str_replace('.csv','.parquet')}")
            }
          })
      }
    }
    
    ## Compiled raw data -------------------------------------------------------
    if (!file.exists(local_paths$frozen_compiled_raw_data)) {
      # This is so compiling individual dataset is cached.
      
      cli_alert_info("Importing {local_config$dataset_id_tmp}_{local_config$dataset_version_tmp} files.")
      raw_data_list = df_lock %>%
        group_by(row_number()) %>% 
        group_map(function(row, i) {
          
          
          ## Import
          ds = arrow::open_dataset(row$freeze_parquet_path)
          df_import =  row$freeze_parquet_path %>%
            arrow::read_parquet() %>% 
            mutate_all(~as.character(.x)) %>%
            mutate(
              file_data = row$file,
              schema_version = local_config$schema_version_tmp,
              dataset_version = local_config$dataset_version_tmp,
              dataset_id = local_config$dataset_id_tmp,
              observation_type = local_config$observation_type_tmp,
              dataset_instance = glue("{local_config$dataset_id_tmp}_{local_config$dataset_version_tmp}"),
            ) %>% 
            arrow::as_arrow_table()
          
          ## DTH specific stuff (development code) -  To migrate to DTH3 notebook
          if (local_config$dataset_id_tmp == 'DTH3'){
            df_import = df_import %>%
              select(-any_of(c('INCLUDE_NOBDRYCHG_L2','INCLUDE_NOUNITCHG_L2',
                               'INCLUDE_NOBDRYCHG_L1AD', 'INCLUDE_NOUNITCHG_L1AD',
                               'PRJL1ADPOPADJ','PRJL1ADPOP',
                               'PRJL2POPADJ','PRJL2POP',
                               'UCNT'))) %>% 
              arrow::as_arrow_table()  }
          
          ## append geo if available in file name
          if (local_config$observation_type_tmp == 'area-level'){
            file_upper = str_to_upper(row$file) 
            geo_tmp = case_when(
              str_detect(file_upper, "ISO2")     ~ "COUNTRY",
              str_detect(file_upper, "COUNTRY")   ~ "COUNTRY",
              str_detect(file_upper, "CITY")   ~ "L1AD",
              str_detect(file_upper, "L1AD") ~ "L1AD",
              str_detect(file_upper, "L1MB") ~ "L1MB",
              str_detect(file_upper, "L1UX") ~ "L1UX",
              str_detect(file_upper, "L1XS") ~ "L1XS",
              str_detect(file_upper, "L1MA") ~ "L1MA",
              str_detect(file_upper, "L1CDP") ~ "L1CDP",
              str_detect(file_upper, "L1") ~ "L1AD",
              str_detect(file_upper, "L3")   ~ "L3",
              str_detect(file_upper, "L25")  ~ "L2_5",
              str_detect(file_upper, "L2_5")  ~ "L2_5",
              str_detect(file_upper, "L2")   ~ "L2",
              TRUE ~ NA  )
            
            ## return to list
            if (!is.na(geo_tmp)) {
              df_import = df_import %>% 
                mutate(geo = geo_tmp) 
              cli_alert("Read into raw_data - {row$file %>% str_replace('.csv','.parquet')}")
              return(df_import)
            } else {stop("NO GEO")}
          }
          
          if (local_config$observation_type_tmp == 'record-level'){
            cli_alert("Read into raw_data - {row$file %>% str_replace('.csv','.parquet')}")
            return(df_import)
          }
          
        }) 
      
      
      ## Bind rows into dataframe
      raw_data = tibble()
      for(i in seq_along(raw_data_list)) {
        #  cli_alert('start binding {i}')
        raw_data <- list(raw_data, collect(raw_data_list[[1]])) %>% rbindlist(fill = T)
        raw_data_list <- raw_data_list[-1]
        #  cli_alert('binded {i}')
      }
      
      ## Cache compiled raw data
      raw_data %>% arrow::write_parquet(local_paths$frozen_compiled_raw_data)
      cli_alert_success("Cached raw_data.parquet for {local_config$dataset_id_tmp}_{local_config$dataset_version_tmp}")
    }
  }
  

  { # Caches   -------------------------------------------------------------
   

    { ## Paths  -------------------------------------------------------------------
      cache_paths = lst(
        ## Folder
        dataset_id_tmp = local_config$dataset_id_tmp,
        dataset_version_tmp = local_config$dataset_version_tmp,
        dataset_instance_tmp = glue("{dataset_id_tmp}_{dataset_version_tmp}"),
        dataset_instance_cache_path = file.path(global_context$path_server_etl_cache, dataset_instance_tmp),
        ## Repo folder
        repo_folder = getwd(),
        ## Variable table
        path_variable_json = file.path(repo_folder, glue("1-var_name.json") ),
        path_variable_csv = file.path(repo_folder, glue("1-var_name.csv") ),
        path_variable_parquet = file.path(repo_folder, glue("1-var_name.parquet") ),
        ## Strata table
        path_strata_json = file.path(repo_folder, glue("2-strata.json") ),
        path_strata_csv = file.path(repo_folder, glue("2-strata.csv") ),
        path_strata_parquet = file.path(repo_folder, glue("2-strata.parquet") ),
        ## Data
        path_cache_int_data = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_int_data_cube.parquet") ),
        path_cache_staged_data = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_staged_data_cube.parquet") ),
        path_cache_metadata_cube_key_template = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_metadata_cube_key_template.parquet") ),
        ## Linkage + Metadata 
        path_cache_metadata_cube_template = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_metadata_cube_template.parquet") ),
        path_cache_staged_metadata = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_staged_metadata_cube.parquet") ),
        ## Utility Caches
        path_cache_utility_1 = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_utility_1.parquet") ),
        path_cache_utility_2 = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_utility_2.parquet") ),
        ## Metadata
        ## OBT objects 
        path_cache_staged_obt = file.path(dataset_instance_cache_path, glue("{dataset_id_tmp}_{dataset_version_tmp}_staged_obt_cube.parquet"))
      )
      
      ##  Create folder if needed
      if (!dir.exists(cache_paths$dataset_instance_cache_path)) {
        dir.create(cache_paths$dataset_instance_cache_path, recursive = TRUE)
        cli_alert_success("Created ETL cache directory `{cache_paths$dataset_instance_cache_path}`")
      }
      
      ## Clear utility cachces
      unlink(cache_paths$path_cache_utility_1)
      unlink(cache_paths$path_cache_utility_2)
      
    }
    
    
    { ## Connect to Cached datasets -------------------------------------------------------
      
      ## Final Data Cube - generated in process_final_admin_data_cube()
      if (file.exists(cache_paths$path_cache_staged_data)){
        final_data_cube = arrow::open_dataset(cache_paths$path_cache_staged_data)
      } else {
        final_data_cube = NULL
      }
      
      ## Metadata Cube Composite Key Template - generated in process_final_admin_data_cube()
      if (file.exists(cache_paths$path_cache_metadata_cube_key_template)){
        metadata_cube_key_template = arrow::read_parquet(cache_paths$path_cache_metadata_cube_key_template)
      } else {
        metadata_cube_key_template = NULL
      }
      
      ## Metadata Cube Template - generated by process_linkage_table()
      if (file.exists(cache_paths$path_cache_metadata_cube_template)){
        metadata_cube_template = arrow::read_parquet(cache_paths$path_cache_metadata_cube_template)
      } else {
        metadata_cube_template = NULL
      }
      
      ## Final Metadata Cube - generated by process_final_metadata_cube()
      if (file.exists(cache_paths$path_cache_staged_metadata)){
        final_metadata_cube = arrow::read_parquet(cache_paths$path_cache_staged_metadata)
      } else {
        final_metadata_cube = NULL
      }
      
      ## Staged OBT  generated by process_preliminary_admin_cube()
      if (file.exists(cache_paths$path_cache_staged_obt)){
        final_obt = arrow::open_dataset(cache_paths$path_cache_staged_obt)
      } else {
        final_obt = NULL
      }
      
      cache_objects = lst(
        final_data_cube = final_data_cube,
        metadata_cube_key_template = metadata_cube_key_template,
        metadata_cube_template = metadata_cube_template,
        final_metadata_cube = final_metadata_cube,
        final_obt = final_obt
      )
      
    }
    
    
    
    
  }
  
  {  # Compile renovation context object -------------------------------------------------------------------
    
    renovation_context = lst(
      ## Local Configs
      schema_version_tmp = local_config$schema_version_tmp,
      dataset_id_tmp = local_config$dataset_id_tmp,
      dataset_version_tmp = local_config$dataset_version_tmp,
      dataset_instance_tmp = glue("{dataset_id_tmp}_{dataset_version_tmp}"),
      observation_type_tmp = local_config$observation_type_tmp,
      partitioned_metadata_config = local_config$partitioned_metadata_config,
      is_partitioned = !is.null(local_config$partitioned_metadata_config),
      is_not_partitioned = !is_partitioned,
      vec__var_names_to_remove = local_config$vec__var_names_to_remove,
      ## Compiled raw data
      raw_data = arrow::open_dataset(local_paths$frozen_compiled_raw_data),
      ## Repo paths
      # repo_version = file.path(global_context$notebook_relative_root,glue("datasets/{local_config$observation_type_tmp}/{dataset_id_tmp}/{dataset_version_tmp}")),
      template_cdbk_path = glue("{cache_paths$repo_folder}/4.0-template__codebook.xlsx"),
      raw_cdbk_path = glue("{cache_paths$repo_folder}/4.1-raw__codebook.xlsx"),
      base_cdbk_path = glue("{cache_paths$repo_folder}/4.2-base__codebook.xlsx"),
      int_cdbk_path = glue("{cache_paths$repo_folder}/4.3-int__codebook.xlsx"),
      ## Denorm
      exception_fields = c('var_def_L1','var_def_L2','var_def_L2_5','var_def_L3'), ## deprecate this for better codebokos (have a by_iso2_var sheet)
      ## DBT
      path_dbt_data = file.path(
        global_context$path_server_dbt_sources,
        glue('{dataset_instance_tmp}_schema-{schema_version_tmp}_data.parquet')
      ),
      path_dbt_metadata = file.path(
        global_context$path_server_dbt_sources,
        glue('{dataset_instance_tmp}_schema-{schema_version_tmp}_metadata.parquet')
      ),
      path_dbt_loading_info_parquet = file.path(
        global_context$path_server_dbt_sources,
        glue('{dataset_instance_tmp}_schema-{schema_version_tmp}_loading.parquet')
      ),
      path_dbt_loading_info_json = file.path(
        global_context$path_server_dbt_sources,
        glue('{dataset_instance_tmp}_schema-{schema_version_tmp}_loading.json')
      )
    ) 
  }
  
  
  { # Return Local Context object ---------------------------------------------

    local_context = c(
      global_context, 
      renovation_context,
      cache_paths, 
      cache_objects,
      local_config = list(
        c(local_config,
          local_paths,
          renovation_render_date = format(Sys.Date(), "%m-%d-%Y"))
      )
    )

    cli_h1(glue("Start Renovation {renovation_context$dataset_instance_tmp}"))
    return(local_context)
  }

}
