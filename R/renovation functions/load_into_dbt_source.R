
load_into_dbt_source = function(context, valid_prelim_admin_cube, training = F){

  
  { # Setup -------------------------------------------------------------------

    ## Input Validation: check for valid admin cube
    if (!valid_prelim_admin_cube) {
      return(cli_abort("Validation failed! Data and Metadata cubes not loaded to dbt source."))
    }

  }
  
  
  { #  Get renovation metadata --------------------------------------------
    
    ## Get file_codebook from data
    list_file_codebooks = context$final_metadata_cube %>% 
      select(file_codebook) %>%
      distinct() %>% 
      collect() %>% 
      pull(file_codebook) %>% 
      str_split(pattern = "\\n") 

    ## Compile
    df_renovation_metadata = tibble(
      dataset_id = context$dataset_id_tmp,
      dataset_version = context$dataset_version_tmp,
      dataset_instance = context$dataset_instance_tmp,
      observation_type = context$observation_type_tmp,
      path_dbt_source_data = context$path_dbt_data,
      path_dbt_source_metadata = context$path_dbt_metadata,
      schema_version = context$schema_version_tmp,
      renovation_render_date = context$local_config$renovation_render_date,
      dataset_renovation_maintainer = context$local_config$dataset_renovation_maintainer,
      dataset_renovation_context_contributor = context$local_config$dataset_renovation_context_contributor,
      dataset_renovation_flags = ifelse(is.null(context$local_config$dataset_renovation_flags),'',local_config$dataset_renovation_flags),
      raw_dataset_dir = context$local_config$raw_dataset_dir,
      ingested_codebooks = list_file_codebooks,
      vec__var_names_to_remove = list(context$local_config$vec__var_names_to_remove),
      dataset_instance_freeze_id = context$local_config$dataset_instance_freeze_id,
      dataset_instance_freeze_path = context$local_config$dataset_instance_freeze_path,
      frozen_compiled_raw_data = context$local_config$frozen_compiled_raw_data,
      ingested_data_files = list(arrow::read_parquet("_lock.parquet"))
    ) %>% 
      assert(is_uniq, dataset_instance)
    
  }
  
  { # Loading -----------------------------------------------------------------
    ## Loading cubes into datawarehouse
    if (valid_prelim_admin_cube){
      
      cli_alert('Start Loading data and metadata cubes into DBT source folder!')
      
      { # Metadata Cube -----------------------------------------------------------
        file.copy(
          from = context$path_cache_staged_metadata,
          to = ifelse(training,
                      file.path("../_datawarehouse/_source/",basename(context$path_dbt_metadata)),
                      context$path_dbt_metadata),
          overwrite = TRUE
        )
      }
      
      { # Data Cube -----------------------------------------------------------
        file.copy(
          from = context$path_cache_staged_data,
          to = ifelse(training,
                      file.path("../_datawarehouse/_source/",basename(context$path_dbt_data)),
                      context$path_dbt_data),
          overwrite = TRUE
        )
      }
      
      { # Renovation information  -----------------------------------------------------------
        
        ## Version control 
        df_renovation_metadata %>%  arrow::write_parquet('_loading.parquet')
        df_renovation_metadata %>% 
          jsonlite::toJSON(auto_unbox = TRUE, pretty = T) %>% 
          writeLines(con =  "_loading.json")
        
        ## Write to DBT Source
        df_renovation_metadata %>% 
          arrow::write_parquet(
            ifelse(training,
                   file.path("../_datawarehouse/_source/",basename(context$path_dbt_loading_info_parquet)),
                   context$path_dbt_loading_info_parquet),
          )
        
        df_renovation_metadata %>% 
          jsonlite::toJSON(auto_unbox = TRUE, pretty = T) %>% 
          writeLines(con = ifelse(training,
                                 file.path("../_datawarehouse/_source/",basename(context$path_dbt_loading_info_json)),
                                 context$path_dbt_loading_info_json))
      }
      
      
      return(cli_alert_success("Validated Data and Metadata cubes loaded to dbt source."))
    }
    
  }
  
} 