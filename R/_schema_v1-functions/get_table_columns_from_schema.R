#' this funciton will take in the df_schema, the xwalk_keys and a particular table in
#' the schema and return the expected columns in that table. If the table doesnt exist
#' in current schema then return NULL 
#' 
#' @param table_tmp: (string) the codebook table name (e.g. `by_var` or `by_var_iso2_year`)
#' @param df_schema_tidy: (dataframe) the tidy version of the schema/linkage dataframe
#' @param xwalk_keys: (dataframe) the seed table containing primary keys for each metadata table
#' 
#' 
#' Example: 
#'    xwalk_keys = etl$xwalk_keys
#'    table_tmp = 'by_var_strata'
#'    table_tmp = 'by_dataset'


get_table_columns_from_schema = function(table_tmp, df_schema_tidy, xwalk_keys){

  # Get primary keys for this table -------------------------------------------------------------------
  table__keys = xwalk_keys %>% 
    filter(table == table_tmp) %>% 
    pull(keys) %>% 
    str_split(';') %>% 
    unlist() %>% 
    str_trim()
  
  #  get all columns in this table  -------------------------------------------------------------
  if (table_tmp%in%df_schema_tidy$table){
    table__columns = df_schema_tidy %>%
      filter(table  == table_tmp) %>% 
      pull(column) %>% 
      c(table__keys,.)
    return(table__columns)
  } else {
    return(NULL)
  }
}

