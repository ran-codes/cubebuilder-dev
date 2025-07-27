#' Returns objects fo ELT 
#'   notebook_relative_root = here()

source_parent('get_denormalized_table')
source_parent('get_etl_status') 
source_parent('generate_relative_path') 

get_global_context = function(root = here()){
  
  cli_alert("Updating Global Context")
  
  { # Setup -------------------------------------------------------------------
    

    {  # Secrets  ---------------------------------------------------------------------
      path_secrets = generate_relative_path(root,".env")
      if (file.exists(path_secrets)){
        dotenv::load_dot_env(file = path_secrets)
        secrets = lst(
          secret_notion_api_key = Sys.getenv("NOTION_API_KEY")
        )
      } else {
        secrets = lst(
          secret_notion_api_key = NULL
        )
      }
    }
    
    
    { # Server + Local Paths ------------------------------------------------------------
      
      ## Declare paths
      server_paths = lst(
        ### Storage
        path_shared_home = here("_shared_storage"),
        path_server_etl_cache = file.path(path_shared_home, '3_cache_temporary'), ## Can be deleted no problem; cache of intermediate files
        path_server_etl_freeze = file.path(path_shared_home, '2_freeze'), ## These should not be deleted as the purpose is long term storage
        path_server_etl_seeds = file.path(path_shared_home, '0_schema'),
        path_server_dbt_sources =  file.path(path_shared_home,"4_standardized"),
        path_server_dbt = file.path(path_shared_home,'5_datawarehouse'),
        path_server_dbt_dev = file.path(path_server_dbt, 'models/dev'),
        path_server_dbt_stage = file.path(path_server_dbt, 'models/stage'),
        path_server_api_metata = file.path(
          path_server_dbt,"api","_production","api__metadata_cube.parquet"
        ),
        
        ## Seeds (DMC Specific/Restricted)
        path_server_dmc = '//files.drexel.edu/colleges/SOPH/Shared/UHC/Projects/Wellcome_Trust/Data Methods Core/',
        path_dmc_seeds = file.path(path_server_dmc,'Dashboards/seeds'),
        path_server_etl_seeds_xwalks = file.path(path_dmc_seeds, '_crosswalks'),
        path_server_etl_seeds_crosswalks =  file.path(path_dmc_seeds,"_crosswalks/"),
        path_server_etl_seeds_spatial = file.path(path_dmc_seeds,"_spatial/"),
        arcgispro_path = file.path(path_server_dmc,'ArcGISPro/SALURBAL_L1UX/'),
        salurbal_gdb_path = file.path(path_server_dmc,'Geodatabases/SALURBAL/'),
        adm1_path = file.path(path_server_etl_seeds_spatial,'adm1_boundaries.parquet'),
        adm1_5pct_path = file.path(path_server_etl_seeds_spatial,'adm1_boundaries_5pct.parquet'),
        l1ad_path = file.path(path_server_etl_seeds_spatial,'l1ad_boundaries.parquet'),
        l1ad_5pct_path = file.path(path_server_etl_seeds_spatial,'l1ad_boundaries_5pct.parquet'),
        l1ad_centroids_path = file.path(path_server_etl_seeds_spatial,'l1ad_centroids.parquet'),
        l1ad_centroids_df_path = file.path(path_server_etl_seeds_spatial,'l1ad_centroids_dataframe.parquet'),
        l1ux_path = file.path(path_server_etl_seeds_spatial,'l1ux_boundaries.parquet'),
        l1ux_5pct_path = file.path(path_server_etl_seeds_spatial,'l1ux_boundaries_5pct.parquet'),
        l2_path = file.path(path_server_etl_seeds_spatial,'l2_boundaries.parquet'),
        l2_5pct_path = file.path(path_server_etl_seeds_spatial,'l2_boundaries_5pct.parquet'),
        l3_path = file.path(path_server_etl_seeds_spatial,'l3_boundaries.parquet'),
        l3_5pct_path = file.path(path_server_etl_seeds_spatial,'l3_boundaries_5pct.parquet')
      )
      
      { ## QC: Validate all server paths
        vec__invalid_server_paths = server_paths %>% 
          discard(~file.exists(.x)) %>% 
          discard(~dir.exists(.x))
        pass = length(vec__invalid_server_paths) == 0
        if (!pass) cli_abort("Server paths are not valid. Please check the paths and try again.")
      }    
      
      local_paths =  lst(
        # repo_clean = 'clean/marts/v1.0',
        # repo_inventory = 'clean/inventory',
        # repo_2_processed = 'clean/2-processed',
        # repo_processed = 'code/marts/v1.0/processed',
        # repo_local_api_dir = "clean/marts/v1.0/azure",
        # portal_mart = '../SALURBAL Dashboard Portal/data-portal/salurbal-data-portal/app/datastore/',
        ## Evidence Reporting
        # repo_reports = generate_relative_path(root,'salurbal-dbt/reports/sources'),
        # repo_reports_source_salurbal_metadata = file.path(repo_reports,'salurbal'),
        # repo_reports_source_templating_data = file.path(repo_reports, 'templating'),
        ### Censorship
        # repo_dmc_censorship = generate_relative_path(root, 'code/admin_core/portal_marts/2 - censorship/'),
        
      )
      
      paths = c(server_paths, local_paths)
      
      
    }
    
  }
  
  
  { # Seeds -------------------------------------------------------------------
    { # Admin Layer Schema   ---------------------------------------------------------------------
      
      admin_layer_context = lst(
        ## Paths
        seed_path_admin_layer_schema_parquet = generate_relative_path(root,'_shared_storage/0_schema/seed-admin-layer-schema.parquet'),
        seed_path_admin_layer_schema_json = generate_relative_path(root,'_shared_storage/0_schema/seed-admin-layer-schema.json'),
        
        ## Schema
        df_admin_layer_schema = arrow::read_parquet(generate_relative_path(root,'_shared_storage/0_schema/seed-admin-layer-schema.parquet')),
        
        ##Composite Keys
        vec__admin_composite_keys_all = df_admin_layer_schema %>% filter(type == 'composite key') %>% pull(name),
        vec__admin_composite_keys_all_never_empty = df_admin_layer_schema %>% 
          filter(type == 'composite key', never_empty) %>% 
          pull(name),
        
        
        ## Variable definition table (df_var_name.csv)
        vec__admin_variable_definition_table_columns = df_admin_layer_schema %>% filter(in_variable_table) %>% pull(name),
        vec__admin_variable_definition_table_columns_never_empty = df_admin_layer_schema %>% filter(in_variable_table, never_empty) %>% pull(name),
        
        ## Strata definition table (df_strata.csv)
        vec__admin_strata_definition_table_columns = df_admin_layer_schema %>% filter(in_strata_table) %>% pull(name),
        vec__admin_strata_definition_table_columns_never_empty = df_admin_layer_schema %>% filter(in_strata_table, never_empty) %>% pull(name),
        vec__admin_variable_definition_table_columns = df_admin_layer_schema %>% filter(in_variable_table) %>% pull(name),
        vec__admin_variable_definition_table_columns_never_empty = df_admin_layer_schema %>% filter(in_variable_table, never_empty) %>% pull(name),
        
        
        #### Metadata
        vec__admin_metadata_composite_keys = df_admin_layer_schema %>% 
          filter(type == 'composite key', in_metadata_table) %>% 
          pull(name),
        vec__admin_metadata_composite_keys_never_empty = df_admin_layer_schema %>% 
          filter(type == 'composite key', in_metadata_table, never_empty) %>% 
          pull(name),
        vec__admin_metadata_columns_all = df_admin_layer_schema %>%
          filter(type == 'metadata attributes', in_metadata_table) %>% 
          pull(name),
        vec__admin_metadata_columns_standard = df_admin_layer_schema %>%
          filter(type == 'metadata attributes', in_metadata_table, default_metadata) %>% 
          pull(name),
        vec__admin_metadata_columns_never_empty = df_admin_layer_schema %>%
          filter(type == 'metadata attributes', in_metadata_table, never_empty) %>% 
          pull(name),
        vec__admin_final_metata_cube_required_columns = df_admin_layer_schema %>%
          filter(in_metadata_table, in_final_metadata_cube ) %>% 
          pull(name),
        
        ## Metadata
        vec__admin_data_composite_keys = df_admin_layer_schema %>% 
          filter(type == 'composite key', in_data_table) %>% 
          pull(name),
        vec__admin_data_composite_keys_never_empty = df_admin_layer_schema %>% 
          filter(type == 'composite key', in_data_table, never_empty) %>% 
          pull(name),
        vec__admin_data_columns_all = df_admin_layer_schema %>% 
          filter(in_data_table, type == 'data attribute') %>% 
          pull(name),
        vec__admin_data_columns_never_empty = df_admin_layer_schema %>% 
          filter(in_data_table, type == 'data attribute', never_empty) %>% 
          pull(name)
        
      )
      
    }
    
    { # Crosswalks --------------------------------------------------------------
      crosswalks = lst(
        path_xwalk_iso2 = file.path(paths$path_server_etl_seeds_crosswalks, 'xwalk_iso2.parquet'),
        xwalk_iso2 = read_parquet(path_xwalk_iso2),
        path_xwalk_l1ad = file.path(paths$path_server_etl_seeds_crosswalks, 'xwalk_l1ad.parquet'),
        xwalk_l1ad = read_parquet(path_xwalk_l1ad),
        path_xwalk_l2 = file.path(paths$path_server_etl_seeds_crosswalks, 'xwalk_l2.parquet'),
        xwalk_l2 = read_parquet(path_xwalk_l2),
        path_xwalk_area_level_observation_id_label = file.path(paths$path_server_etl_seeds_crosswalks, 
                                                               'xwalk_area_level_observation_id_label.parquet'),
        xwalk_area_level_observation_id_labels = read_parquet(path_xwalk_area_level_observation_id_label),
        xwalk_keys = generate_relative_path(root,"_shared_storage/0_schema/templates/4-codebook_keys.csv") %>% 
          read_csv(show_col_types = FALSE) %>% 
          unpack_string_column(.,"keys")
      )  
    }
    
    
    { # Templates ---------------------------------------------------------------
      
      templates = lst(
        template__var_name = generate_relative_path(root,"_shared_storage/0_schema/templates/1-var_name_template.csv") %>% read_csv(show_col_types = FALSE),
        template__strata = generate_relative_path(root,"_shared_storage/0_schema/templates/2-strata_template.csv") %>% read_csv(show_col_types = FALSE),
        template__data = generate_relative_path(root,"_shared_storage/0_schema/templates/5-data_template.csv") %>% read_csv(show_col_types = FALSE),
        template__linkage = generate_relative_path(root,"_shared_storage/0_schema/templates/3-linkage_template.csv") %>% read_csv(show_col_types = FALSE))
      
    }
    
    { # Renovation Seeds  -------------------------------------------------------
      seeds = lst(
        src = import_salurbal_xslx_cdbk(generate_relative_path(root, '_shared_storage/0_schema/src.xlsx'), src = T),
        templating_data = import_salurbal_xslx_cdbk(generate_relative_path(root, '_shared_storage/0_schema/templating_data.xlsx'), src = T),
        vec__registered_keys = find_codebook_templating_keys(templating_data),
        templating_dictionary = jsonlite::read_json(generate_relative_path(root, '_shared_storage/0_schema/templating_dictionary.json')),
        df_templating_data = arrow::read_parquet(generate_relative_path(root, '_shared_storage/0_schema/templating_data.parquet')),
        # df__codebook_proto = arrow::read_parquet(paste0(paths$path_server_etl_seeds,"_prototype/codebook_prototype.parquet")) %>% 
        #   select( -dataset_id, -license, -fair) %>% 
        #   distinct(),
        ## Current Production Metadata
        df__prod_variables =  arrow::read_parquet(generate_relative_path(root, '_shared_storage/0_schema/df__prod_variables.parquet'))
      )  
    }
  }
  
  { # Production --------------------------------------------------------------

    { # SALURBAL Cubes   ---------------------------------------------------------------------
      
      cube = lst(
        
        
        ## Schema v1 D
        path_cache_source_v1 = file.path(paths$path_server_dbt_sources, 'schema_v1_source'),
        path_cache_salurbal_metadata_cube_v1 = file.path(path_cache_source_v1, '_salurbal_metadata_cube_v1.parquet'), 
        cache_salurbal_metadata_cube_v1 = ifelse(file.exists(path_cache_salurbal_metadata_cube_v1),
                                                 arrow::open_dataset(path_cache_salurbal_metadata_cube_v1),
                                                 list(NULL)),
        path_cache_salurbal_data_cube_v1 = file.path(path_cache_source_v1, '_salurbal_data_cube_v1.parquet'),
        cache_salurbal_data_cube_v1 =  ifelse(file.exists(path_cache_salurbal_data_cube_v1),
                                              arrow::open_dataset(path_cache_salurbal_data_cube_v1),
                                              list(NULL)),
        ## Schema v2
        path_cache_source_v2 = file.path(paths$path_server_dbt_sources, 'schema_v2_source'),
        path_cache_salurbal_metadata_cube_v2 = file.path(path_cache_source_v2, '_salurbal_metadata_cube_v2.parquet'),
        cache_salurbal_metadata_cube_v2 = ifelse(file.exists(path_cache_salurbal_metadata_cube_v2),
                                                 arrow::open_dataset(path_cache_salurbal_metadata_cube_v2),
                                                 list(NULL)),
        path_cache_salurbal_data_cube_v2 = file.path(path_cache_source_v2, '_salurbal_data_cube_v2.parquet'),
        cache_salurbal_data_cube_v2 =  ifelse(file.exists(path_cache_salurbal_data_cube_v2),
                                              arrow::open_dataset(path_cache_salurbal_data_cube_v2),
                                              list(NULL)),
        
        
        ## Harmonized production
        path_cache_salurbal_data_cube = file.path(paths$path_server_dbt_sources, '_salurbal_data_cube.parquet'),
        cache_salurbal_data_cube = ifelse(file.exists(path_cache_salurbal_data_cube),
                                          arrow::open_dataset(path_cache_salurbal_data_cube),
                                          list(NULL)),
        path_cache_salurbal_metadata_cube = file.path(paths$path_server_dbt_sources, '_salurbal_metadata_cube.parquet'),
        cache_salurbal_metadata_cube = ifelse(file.exists(path_cache_salurbal_metadata_cube),
                                              arrow::open_dataset(path_cache_salurbal_metadata_cube),
                                              list(NULL))
        
      )
    }
    
    
    
    
    {
      # Inventory  ---------------------------------------------------------------------
      inventory = lst(
        df_var_details = arrow::read_parquet(generate_relative_path(root,'clean/inventory/df_var_details.parquet')),
        df_primary_metadata = readRDS(generate_relative_path(root,'clean/inventory/df_primary_metadata.rds')),
        df_domains = arrow::read_parquet(generate_relative_path(root,"clean/inventory/df_domains.parquet")),
        df_subdomains = arrow::read_parquet(generate_relative_path(root,"clean/inventory/df_subdomains.parquet")),
      )
    }
    
    
    {  # Censorship --------------------------------------------------------------
      
      # df_censorship = tibble(
      #   censorship_file = list.files(
      #     paths$repo_dmc_censorship,
      #     pattern = '.csv') ,
      #   censorship_date = censorship_file %>% 
      #     str_remove(".csv") %>% 
      #     str_split("_") %>% 
      #     map(~.x %>% tail(n=1)) %>% 
      #     unlist() %>% 
      #     lubridate::as_date() ) %>%
      #   filter(!str_detect(censorship_file,'_template')) %>%
      #   filter(censorship_date == max(censorship_date))
      
      # df_censorship = file.path(paths$repo_dmc_censorship, df_censorship$censorship_file) %>%
      #   read_csv(show_col_types = FALSE) %>% 
      #   mutate(censorship_date = df_censorship$censorship_date) %>% 
        # select(censorship_date, everything())
      
      # df_censorship %>%
      #   mutate(across(where(is.character), ~gsub("\r", "", .))) %>% 
      #   jsonlite::write_json(file.path(paths$repo_dmc_censorship, '.variable_censorship.json'),
      #                        pretty = T)
      # 
      # vec__post_censorship_vars_to_keep = df_censorship %>%
      #   filter(keep == 1) %>%
      #   pull(var_name)
      # 
      # censorship = lst(
      #   df_censorship = df_censorship,
      #   vec__post_censorship_vars_to_keep,
      #   new_censorship_template_csv_path = file.path(
      #     paths$repo_dmc_censorship,
      #     'variable_censorship_template_{format(Sys.Date(), "%Y%m%d")}.csv'),
      #   new_censorship_template_json_path = file.path(
      #     paths$repo_dmc_censorship,
      #     'variable_censorship_template_{format(Sys.Date(), "%Y%m%d")}.json')
      #   )
        

    }
    
    
  }
  
 
  
  { # Return ------------------------------------------------------------------

    ## Final global context object
    global_context = c(
      notebooks,
      paths,
      crosswalks,
      templates,
      seeds,
      admin_layer_context,
      inventory,
      # censorship,
      secrets,
      cube
    )
    
    ## Cache global context
    saveRDS(global_context, file = generate_relative_path(root,"clean/global_context.rds"))
    
    ## Return
    cli_alert_success("Global Context Updated")
    return(global_context)    
  }
}
 
