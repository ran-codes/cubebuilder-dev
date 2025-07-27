#' Setup ETL and imports seeds for dataset specific renovation
#'    - ETL Init: sets up etl folders 
#'    - ETL backup: if not backed up in etl/version/ then backup as historical storage
#'    - Import raw_data: Imports data from historical backup 
#'    - Dataset object: 
#' 

source_parent('get_server_path')
source_parent('get_gh_path')


get_setup_imports = function(dataset_id_tmp, status_tmp, etl, raw_dataset_dir, version_tmp, date_tmp, env = 'dev'){

  { # Setup -------------------------------------------------------------------
    db_path = glue('{etl$dmc_path}{raw_dataset_dir}')
    db_etl_path = glue("{db_path}_etl/")
    db_etl_version_path =  glue("{db_etl_path}{dataset_id_tmp}_{version_tmp}/")
    lock_file = glue("{db_etl_version_path}_source.csv")
    locked = file.exists(lock_file)
    
    if (!dir.exists(db_etl_path)) {
      dir.create(db_etl_path, recursive = TRUE)
      cli_alert_success("Created Server ETL directory `{db_etl_path}`")
    }
    
    if (!dir.exists(db_etl_version_path)) {
      dir.create(db_etl_version_path, recursive = TRUE)
      cli_alert_success("Created Server ETL version directory `{db_etl_version_path}`")
    }
  }
  
  { # Initialize folders/files --------------------------------------------------------
  
    if (!locked) {
      df_lock =  status_tmp$df_files_to_process %>%
        arrange(file) %>%
        mutate(size_mb = size / 10 ^ 6) %>%
        select(file, size_mb)
      df_lock %>%  write_csv(glue("{db_etl_version_path}_source.csv"))
      df_lock %>%  write_csv(glue("datasets/{dataset_id_tmp}/{version_tmp}/_source.csv"))
      locked = T
      cli_alert_success("Created lock file (_source.csv) for {dataset_id_tmp}_{version_tmp}")
    }
    
    if (locked) {
      df_lock = read_csv(lock_file) %>%
        mutate(file_name = str_remove(file, '.csv'),
               path = glue("{db_path}{file}"),
               etl_parquet_path  = glue("{db_etl_path}/{dataset_id_tmp}_{version_tmp}/{file_name}.parquet"))
    }
  }
  
  { # Snapshot: import lock file and check freshness vs server folder --------------------------------------------------------
    df_files =  status_tmp$df_files
    df_files_unprocessed = df_files %>% 
      filter(!file %in% df_lock$file) %>% 
      mutate(status = "unprocessed") %>% 
      select(file, status)
    df_files_frozen_missing_in_db = df_lock %>% 
      filter(!file%in%df_files$file)  %>% 
      mutate(status = "frozen_but_missing")%>% 
      select(file, status)
    df_files_processed = df_lock  %>% 
      mutate(status = "processed")%>% 
      select(file, status) 
    if (env == 'dev' & nrow(df_files_unprocessed) > 0) {
      cli_alert_danger('There are unprocessed  {dataset_id_tmp} files.')
      cli_alert("Coordinate with DMC to update ETL {version_tmp} to next version.")
      df_files_unprocessed %>%
        pull(file) %>%
        walk( ~ cli_alert_warning("unprocessed: {.x}"))
    } else if (env == 'dev' & nrow(df_files_frozen_missing_in_db)>0){
      cli_alert_danger('There are frozen {dataset_id_tmp} files missing from server')
      df_files_frozen_missing_in_db %>%
        pull(file) %>%
        walk( ~ cli_alert_warning("missing: {.x}"))
    } else {
      cli_alert_success('Lock file in sync with server')
    }
    df_snapshot = list(df_files_processed,
                       df_files_unprocessed,
                       df_files_frozen_missing_in_db) %>%
      bind_rows() %>%
      mutate(dataset = dataset_id_tmp,
             version = version_tmp) %>%
      select(file, status, dataset, version)
  }
  
  
  { # Freeze: Version specific backups  -------------------------------------------
    
    ## Get unfrozen files
    frozen_files = list.files(db_etl_version_path) %>% 
      discard(~.x=='_source.csv') %>% 
      str_remove(".parquet")
    if (length(frozen_files)==0){
      freeze_complete = F
      df_unfrozen_files = status_tmp$df_files_to_process
    }
    if ((length(frozen_files)>0) ){
      df_unfrozen_files = df_lock %>% filter(!file_name%in%frozen_files) 
      freeze_complete = nrow(df_unfrozen_files) == 0
    }
    if (freeze_complete) cli_alert_success("{dataset_id_tmp}_{version_tmp} data already frozen.")
    
    ## Freeze unfrozen files
    if (!freeze_complete){
      df_unfrozen_files %>%
        group_by(row_number()) %>%
        group_walk( ~ {
          row = .x 
          if (!file.exists(row$etl_parquet_path)) {
            row$path %>%
              read_csv() %>%
              arrow::write_parquet(sink = row$etl_parquet_path)
            cli_alert_success("etl parquet backup {row$file %>% str_replace('.csv','.parquet')}")
          }
        })
    }
  }
  

  { # Import raw_data  -------------------------------------------------------------
    if (env != 'snapshot'){
      cli_alert_info("Importing {dataset_id_tmp}_{version_tmp} files.")
      raw_data_list = df_lock %>%
        group_by(row_number()) %>% 
        group_map(function(row, i) {
          # row = df_lock %>% slice(4)
          
          
          ## Setup
          # cli_alert('start reading ${row$file}')
          ds = arrow::open_dataset(row$etl_parquet_path)
          n_sample = case_when(
            env == 'prod' ~ nrow(ds),
            env != 'prod' & dataset_id_tmp == 'DTH3' & nrow(ds) <= 5*10^5 ~ nrow(ds),
            env != 'prod' & dataset_id_tmp == 'DTH3' ~ 5*10^5, 
            env != 'prod' & nrow(ds) >  50000 ~ 5*10^4,
            env != 'prod' & nrow(ds) <= 50000 ~ nrow(ds)) 
          
          ## Import whole (prod) or sample (dev)
          set.seed(123)
          df_import =  row$etl_parquet_path %>%
            arrow::read_parquet() %>%
            sample_n(n_sample) %>% 
            mutate(file_data = row$file) %>% 
            mutate_all(~as.character(.x))
          
          ## DTH specific stuff (development code)
          if (dataset_id_tmp == 'DTH3'){
            df_import = df_import %>%
              select(-any_of(c('INCLUDE_NOBDRYCHG_L2','INCLUDE_NOUNITCHG_L2',
                               'INCLUDE_NOBDRYCHG_L1AD', 'INCLUDE_NOUNITCHG_L1AD',
                               'PRJL1ADPOPADJ','PRJL1ADPOP',
                               'PRJL2POPADJ','PRJL2POP',
                               'UCNT'))) %>% 
              arrow::as_arrow_table()  }
          
          ## Conversion to Arrow table for performance
          df_import = df_import %>% arrow::as_arrow_table()
          
          ## append geo if available in file name
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
          
        }) 

      ## Bind rows into dataframe
      raw_data = tibble()
      for(i in seq_along(raw_data_list)) {
        #  cli_alert('start binding {i}')
        raw_data <- list(raw_data, collect(raw_data_list[[1]])) %>% rbindlist(fill = T)
        raw_data_list <- raw_data_list[-1]
        #  cli_alert('binded {i}')
      }
      
    }
    if (env == 'snapshot') {raw_data = NULL}
  }
  
  {  # Dataset object -------------------------------------------------------------------

    final = lst(
      ## Flags
      is__intermediate_staging = F,
      is__hierarchical_linkages = F,
      hierachical_linkage_sheets = c(),
      ## Seeds
      dataset_id_tmp = dataset_id_tmp,
      version_tmp = version_tmp,
      raw_data = raw_data,
      dataset_status = get_etl_status(dataset_id_tmp, version_tmp)$status,
      cycle = dataset_status$cycle,
      repo_version = file.path(etl$notebook_relative_root,glue("datasets/{dataset_id_tmp}/{version_tmp}")),
      template_cdbk_path = glue("{repo_version}/4.0-template__codebook.xlsx"),
      raw_cdbk_path = glue("{repo_version}/4.1-raw__codebook.xlsx"),
      base_cdbk_path = glue("{repo_version}/4.2-base__codebook.xlsx"),
      int_cdbk_path = glue("{repo_version}/4.3-int__codebook.xlsx"),
      final_cdbk_path = glue("{repo_version}/4.4-final__codebook.xlsx"),
      db_etl_path=db_etl_path,
      ## Denorm
      exception_fields = c('var_def_L1','var_def_L2','var_def_L2_5','var_def_L3'),
      denormalized_fields = c(names(etl$template__data),
                              etl$template__linkage$field,
                              exception_fields) %>% 
        unique() %>% 
        sort(),
      ## ETL
      etl_denorm_index = which(names(etl)=="denorm"),
      ## snapshot
      df_snapshot = df_snapshot %>% 
        mutate(cycle = cycle,
               status = status %>% recode("processed" = "frozen")) %>% 
        rename(file_status = status),
      ## V2 Datawarehouse
      dataset_instance_tmp = glue("{dataset_id_tmp}_{version_tmp}"),
      path_dbt_data = glue('{etl$dbt_prod_data_internal}/{dataset_instance_tmp}_internal.parquet'),
      path_dbt_metadata = glue('{etl$dbt_prod_metadata_denorm}/{dataset_instance_tmp}_metadata.parquet')
    ) %>% 
      c(.,etl)
    
    if (env == 'dev'){
      dfa <<-raw_data 
    }
    
    cli_h1(glue("Start Renovation {final$dataset_instance_tmp}"))
    return(final)
  }

}
