#' get the status of our database. Our starting point are the folder names
#' in the repo>datasets. We the operationalize two tables:
#' 
#'  `status` will indicate progress on each dataset and contains the following columns:
#'     - `seed`: Boolean. True if the following paths/files exists the following paths/files exists

#'              - `repo/datasets/{dataset}/` 
#'              - `repo/datasets/{dataset}/README.md` 
#'              - `repo/datasets/{dataset}/intermediate/` 
#'              - `R/_etl/etl_{dataset}.R` 
#'     - `setup`: Boolean. True if the following paths/files exists
#'              - `repo/{dataset}/1-var_name.csv`` 
#'              - `repo/{dataset}/2-strata.csv` 
#'              - `server/{dataset}/clean/data.csv` 
#'     - `linkage`: Boolean. True if the following paths/files exists
#'              - `repo/{dataset}/3-linkage.csv` 
#'     - `schema`: Boolean. True if the following paths/files exists
#'              - `repo/{dataset}/3-schema.png`
#'              - `repo/{dataset}/intermediate/__codebook_by_var.csv` + ETC
#'     - `base_codebooks`: Boolean. True if the following paths/files exists
#'              - `repo/{dataset}/intermediate/base__codebook_by_var.csv` + ETC
#'     - `int_codebooks`: Boolean. True if the following paths/files exists
#'              - `repo/{dataset}/intermediate/int__codebook_by_var.csv` + ETC
#'     - `final_codebooks`: Boolean. True if the following paths/files exists
#'              - `repo/{dataset}/intermediate/final__codebook_by_var.csv` + ETC
#'     - `val_codebooks`: Boolean. True if the following paths/files exists
#'              - `repo/{dataset}/codebook_by_var.csv` + ETC
#'     - `denormalized`: Boolean. True if the following paths/files exists
#'              - `server/{dataset}/clean/denormalized.csv`
#'              - `server/{dataset}/clean/denormalized.parquet`
#'              - `/{dataset}/denormalized-public-subset.csv` 


source_parent('get_server_path')

get_etl_status = function(dataset_id_tmp = NA, version_tmp = 'v1.0'){
  
  
  { # Setup -------------------------------------------------------------------
    
    ## Local Objects
    version_regex =  "^v[0-9]+\\.[0-9]+$"
    
    ## Get datasets currently in repository
    df_datasets_raw = tibble(dataset_id = list.files(path = "datasets/")) %>% 
      filter(!str_detect(dataset_id,'.md|_src|_loading')) %>% 
      group_by(row_number()) %>% 
      group_map(~{
        dataset_id_tmp = .x$dataset_id
        vec__versions = list.files(path = paste0("datasets/",dataset_id_tmp)) %>% 
          keep(~str_detect(.x,version_regex)) %>% 
          list()
        tibble(dataset_id = dataset_id_tmp) %>% 
          mutate(version = vec__versions) %>% 
          unnest(cols = 'version')
      }) %>% 
      bind_rows() %>% 
      add_count(dataset_id, name = 'n_versions') %>% 
      arrange(desc(n_versions), dataset_id)
    
    ## Filter for specific dataset_id, version
    df_datasets = df_datasets_raw
    if (!is.na(dataset_id_tmp)) df_datasets = filter(df_datasets, dataset_id == dataset_id_tmp)
    if (!is.na(version_tmp)) df_datasets = filter(df_datasets, version == version_tmp)
    
    ## If a new dataset_version then create a new row
    if (nrow(df_datasets)==0)  df_datasets = tibble(dataset_id = dataset_id_tmp, 
                                                    version = version_tmp) 
  }
  
  { # df_status ---------------------------------------------------------------
    
    df__template = df_datasets %>%
      group_by(row_number()) %>% 
      group_map(~{
        dataset_id_tmp = .x$dataset_id
        version_tmp = .x$version
        ## For each ETL instance, here are the indvidual paths/items we will track
        dfa = tibble(
          dataset_id = dataset_id_tmp,
          repo_folder = glue("datasets/{dataset_id_tmp}"),
          repo_md = glue("{repo_folder}/README.md"),
          repo_version = glue("{repo_folder}/{version_tmp}"),
          repo_func = glue("R/_etl/etl_{dataset_id_tmp}_{version_tmp}.R"),
          ## Setup
          repo_var_name = glue("{repo_version}/1-var_name.csv"),
          repo_strata = glue("{repo_version}/2-strata.csv"),
          repo_linkage = glue("{repo_version}/3-linkage.csv"),
          # repo_schema = glue("{repo_version}/3-schema.png"),
          repo_templates = glue("{repo_version}/4.0-template__codebook.xlsx"),
          ## base_codebooks
          repo_raw_codebook = glue("{repo_version}/4.1-raw__codebook.xlsx"),
          ## base_codebooks
          repo_base_codebook = glue("{repo_version}/4.2-base__codebook.xlsx"),
          ## int_codebooks
          repo_int_codebook = glue("{repo_version}/4.3-int__codebook.xlsx"),
          ## final_codebooks
          repo_final_codebook = glue("{repo_version}/4.4-final__codebook.xlsx"),
          ## production
          dbt_data = glue("{etl$dbt_path}/sources/data_internal/{dataset_id_tmp}_{version_tmp}_internal.parquet"),
          dbt_metadata = glue("{etl$dbt_path}/sources/metadata/{dataset_id_tmp}_{version_tmp}_metadata_by_var.parquet")
        ) %>% 
          pivot_longer(-dataset_id,
                       names_to = 'item',
                       values_to = 'path') %>% 
          mutate(
            version = version_tmp,
            cycle = case_when(
              item%in%c('repo_folder','repo_md','repo_version','repo_func') ~ 'seed',
              item%in%c('repo_var_name','repo_strata')~'setup',
              item%in%c('repo_linkage')~'linkage',
              item%in%c('repo_schema','repo_templates')~'schema',
              item%in%c('repo_raw_codebook')~'raw_codebooks',
              item%in%c('repo_base_codebook')~'base_codebooks',
              item%in%c('repo_int_codebook')~'int_codebooks',
              item%in%c('repo_final_codebook')~'final_codebooks',
              item%in%c('dbt_data','dbt_metadata')~'production'),
            exists = file.exists(path)   ) %>% 
          select(dataset_id, version, everything())
        return(dfa)
      }) %>% 
      bind_rows()
    
    df_status = df__template %>%
      group_by(dataset_id, version, cycle) %>% 
      summarize(value = ifelse(all(exists),T,NA), 
                .groups = 'drop') %>% 
      pivot_wider(names_from = 'cycle', values_from = 'value' ) %>% 
      rowwise() %>%
      mutate(cycle = case_when(
        all(seed, setup, linkage, schema, raw_codebooks, base_codebooks, int_codebooks, final_codebooks, production)~"production",
        all(seed, setup, linkage, schema, raw_codebooks, base_codebooks, int_codebooks, final_codebooks)~"final_codebooks",
        all(seed, setup, linkage, schema, raw_codebooks, base_codebooks, int_codebooks)~"int_codebooks",
        all(seed, setup, linkage, schema, raw_codebooks, base_codebooks)~"base_codebooks",
        all(seed, setup, linkage, schema, raw_codebooks)~"raw_codebooks",
        all(seed, setup, linkage, schema)~"schema",
        all(seed, setup, linkage)~"linkage",
        all(seed, setup)~"setup",
        TRUE ~ "needs_setup"
      )) %>% 
      ungroup()%>% 
      select(dataset_id, version, cycle,
             seed, setup, linkage, schema, 
             raw_codebooks,
             base_codebooks, 
             int_codebooks, 
             final_codebooks,
             production) %>% 
      arrange(final_codebooks, int_codebooks, base_codebooks, raw_codebooks,
              schema,   linkage, setup, seed, dataset_id) 
    
    if (!is.na(dataset_id_tmp)) {
      df_status = df_status %>% 
        mutate_all(~ifelse(is.na(.x),F,.x))
    }
    
  }
  
  
  { # df_path  ----------------------------------------------------------------
    df_path = df_status %>% 
      rowwise() %>% 
      mutate(
        path_denormalized = glue("{etl$dmc_path}Dashboards/dbt/v1.0/stage/{dataset_id_tmp}_{version_tmp}denorm_subset.parquet"),
        path_strata = ifelse(
          setup,
          glue("datasets/{dataset_id}/{version_tmp}/2-strata.csv"),NA) 
      ) %>% 
      select(dataset_id, path_denormalized, path_strata) %>% 
      ungroup()
  }
  
  
  
  {  # Final -------------------------------------------------------------
    final = list(
      status = df_status,
      path = df_path,
      items = df__template
    )
    return(final)}
  
}
