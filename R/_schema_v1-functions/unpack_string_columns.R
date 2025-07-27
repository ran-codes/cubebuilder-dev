#' takes in df and unpacks potential packed collumns including:
#'      - `_year`
#'      
#' 
#' Example:
#'      active__table = i$base__list_codebooks$by_var_iso2_year
#'      active__table = i$base__list_codebooks$by_var_iso2_year %>% base__by_var_raw
#'      active__table = i$final__codebooks$by_dataset 
#'      active__table = i$final__codebooks$by_var 
#'      active__table = i$final__codebooks$by_iso2_year 
#'      active__table = i$final__codebooks$by_var_iso2_year 
#'      active__table = src_import %>% map(~.x[[table_name]]) %>% discard(~is.null(.x)) %>%  bind_rows()
#'      active__table = .x; columns = list(etl$core_composite_keys)

source_parent('unpack_year')

unpack_string_column  = function(active__table, columns, except_source = true){
  
  df_tidy = active__table
  
  columns %>% 
    unlist() %>% 
    walk(~{
      if (.x %in% names(df_tidy)) {
        df_tidy <<- df_tidy %>% 
          rowwise() %>%
          mutate(!!.x := unpack_string(!!sym(.x))) %>%
          ungroup() %>%
          unnest(cols = !!sym(.x))
      }
    })
  
  
  return(df_tidy)
}



unpack_columns = function(df, list_columns){
  
  ## Temp objects
  df_tmp = df
  columns_all = unlist(list_columns)
  
  ## QC inputs
  if (length(columns_all) == 0){
     cli_abort('list of columns to unpack is empty')
     return(df)
  }
  

  ## Unpack year
  has_year = all(
    'year' %in% columns_all,
    'year' %in% names(df_tmp)
  )
  if (has_year){
    df_tmp = df_tmp %>% 
      rowwise() %>% 
      mutate(`year` = unpack_year_string(year)) %>% 
      ungroup() %>% 
      unnest(cols = `year`)
  } 
  
  ## Unpack everything else
  columns_remaining = columns_all %>% 
    keep(~.x %in% names(df_tmp)) %>% 
    discard(~.x == 'year')
  columns_remaining %>% 
    walk(~{
      df_tmp = df_tmp %>% 
        rowwise() %>%
        mutate(!!.x := unpack_string(!!sym(.x))) %>%
        ungroup() %>%
        unnest(cols = !!sym(.x))
    })
  
  ## Return
  return(df_tmp)
  
}
  


unpack_string_columns  = function(active__table, except_source = true){
  
  df_tidy = active__table
  
  if ('year'%in%names(active__table)){
    df_tidy = df_tidy %>% 
      rowwise() %>% 
      mutate(`year` = unpack_year_string(year)) %>% 
      ungroup() %>% 
      unnest(cols = `year`)
  } 
  # if ('source'%in%names(active__table)){
  #   df_tidy = df_tidy %>% 
  #     rowwise() %>% 
  #     mutate(source = unpack_string(source)) %>% 
  #     ungroup() %>% 
  #     unnest(cols = `source`)
  # } 
  if ('var_name_raw'%in%names(active__table)){
    df_tidy = df_tidy %>% 
      rowwise() %>% 
      mutate(var_name_raw = unpack_string(var_name_raw)) %>% 
      ungroup() %>% 
      unnest(cols = var_name_raw)
  }
  if ('dataset_id'%in%names(active__table)){
    df_tidy = df_tidy %>% 
      rowwise() %>% 
      mutate(dataset_id = unpack_string(dataset_id)) %>% 
      ungroup() %>% 
      unnest(cols = dataset_id) 
  }
  df_tidy = df_tidy %>% 
    mutate_all(~as.character(.x))
  
  
  
  return(df_tidy)
}
