#' this funciton will take in a linkage.csv and darw out the schema.png at the same location of the 
#' linkage file. 
#' 
#' @param linkage_path: (string) the path to the linkage .csv
#'
#'
#' Example: 
#'    df_linkage_tidy = schema$df_schema_tidy
#'


draw_schema_from_linkage = function(df_linkage_tidy, dataset_id_tmp, i){
  
  { # setup -------------------------------------------------------------------------
    metadata_table_names = unique(df_linkage_tidy$table)
    metadata_tables = metadata_table_names %>% 
      map(~{
        pks = etl$xwalk_keys %>%  filter(table==.x) %>% pull(keys)
        table_columns  = df_linkage_tidy %>% filter(table == .x) %>% pull(column) 
        columns = c(pks, table_columns)
        tibble()%>% 
          mutate(!!!setNames(rep(NA, length(columns)),columns)) %>% 
          return() } ) %>% 
      set_names(metadata_table_names) 
    data_table = list('data' = etl$template__data)
    tables = c(metadata_tables,data_table)
    
  }
  
  { # dm --------------------------------------------------------
    
    dm = tables %>% as_dm(tables)
    
    ## Add Primary Keys
    names(tables) %>%
      walk(function(table_tmp){
        pks = etl$xwalk_keys %>%  filter(table==table_tmp) %>% pull(keys)
        dm <<- dm %>% dm_add_pk(table = !!table_tmp , columns = !!pks, force = T)
      })
    
    ## Add Foreign Keys
    names(tables) %>% 
      discard(~.x=='data') %>% 
      walk(function(table_tmp){
        fks = etl$xwalk_keys %>%  filter(table==table_tmp) %>% pull(keys)
        dm <<- dm %>% dm_add_fk(table = !!table_tmp , 
                                columns = !!fks, 
                                ref_table = data,
                                ref_columns = !!fks) 
      })
    
  }
  
  { # Draw --------------------------------------------------------------------
    
    ## Draw
    dm %>%
      dm_set_colors(aliceblue = starts_with("by")) %>%
      dm_draw(rankdir = "LR", view_type = "all") %>%
      export_svg() %>% 
      charToRaw %>% 
      rsvg_png(glue("{i$repo_version}/3-schema.png"))    
    
    cli_alert("Created schema.png for {dataset_id_tmp}")
    
  }
  
}

