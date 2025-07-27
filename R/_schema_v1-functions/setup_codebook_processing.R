#' provides utilities for the {brain} section of codebook processing.
#' 
#' 

export_processed_codebooks = function(df, path_processed, path_base){
  write_json(df,path_processed, pretty = T, na = 'string')
  fwrite(df, path_base)
  
}

copy_csv_as_json = function(path_csv){
  if (file.exists(path_csv)){
    path_json = str_replace(path_csv, '.csv', '.json')
    path_processed_json = str_replace(path_json, '/raw__', '/processed__')
    df = path_csv %>% 
      read_csv() %>% 
      mutate_all(~as.character(.x))
    if (validate_df_utf8(df)){
      ## Write copy of raw codbeook
      write_json(df, path_json, pretty = T,na = 'string')
      ## initialize processed codebook if not exist
      if(!file.exists(path_processed_json)){write_json(df, path_processed_json, pretty = T,na = 'string')}
    }
    return(df)
  } else {
    return(NULL)
  }
}

setup_codebook_processing = function(dataset_id_tmp, i){
  
  # 1.  paths ------------------------------------------------------
  paths = lst(
    intermediate = glue('datasets/{dataset_id_tmp}/intermediate'),
    archive = glue('{intermediate}/archive'),
    ## by_dataset
    raw_by_dataset = glue('{archive}/raw__codebook_by_dataset.csv'),
    raw_by_dataset_json = str_replace(raw_by_dataset,'.csv','.json'),
    processed_by_dataset_json = glue('{archive}/processed__codebook_by_dataset.json'),
    base_by_dataset = glue('{intermediate}/base__codebook_by_dataset.csv'),
    ## by_var
    raw_by_var = glue('{archive}/raw__codebook_by_var.csv'),
    raw_by_var_json = str_replace(raw_by_var,'.csv','.json'),
    processed_by_var_json = glue('{archive}/processed__codebook_by_var.json'),
    base_by_var = glue('{intermediate}/base__codebook_by_var.csv'),
    ## by_var_iso2_year
    raw_by_var_iso2_year = glue('{archive}/raw__codebook_by_var_iso2_year.csv'),
    raw_by_var_iso2_year_json = str_replace(raw_by_var_iso2_year,'.csv','.json'),
    processed_by_var_iso2_year_json = glue('{archive}/processed__codebook_by_var_iso2_year.json'),
    base_by_var_iso2_year = glue('{intermediate}/base__codebook_by_var_iso2_year.csv'),
  )
  
  # 1.  raw codebook copy + import  ------------------------------------------------------
  raw = lst(
    raw__by_dataset =  copy_csv_as_json(paths$raw_by_dataset),
    raw__by_var = copy_csv_as_json(paths$raw_by_var),
    raw__by_var_iso2_year = copy_csv_as_json(paths$raw_by_var_iso2_year)
  )
  
  
  # Side effects ------------------------------------------------------------
  
  
  
  ## initialize base__by_dataset ---------------------------------------------
  if (is.null(raw$raw__by_dataset)&(!file.exists(paths$base_by_dataset))){
    base__by_dataset = tibble(
      dataset_id = i$dataset_id_tmp,
      dataset_submission_date= get_date_from_data_file_name(i$file_data_tmp),
      dataset_notes = NA) %>% 
      mutate_all(~as.character(.x))
    export_processed_codebooks(base__by_dataset, paths$processed_by_dataset_json, paths$base_by_dataset)
  }
  
  
  # final -------------------------------------------------------------------
  
  
  final = c(paths,
            raw)
  return(final)
  
}