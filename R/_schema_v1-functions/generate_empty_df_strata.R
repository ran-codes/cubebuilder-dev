#' generates an empty df_strata
#' 
#'  @param df_var_name
#'  @param i
#'  


generate_empty_df_strata = function(df_var_name, context){
  
  df_strata =  context$template__strata %>% 
    bind_rows(df_var_name) %>% 
    select(all_of(context$vec__admin_strata_definition_table_columns)) %>% 
    mutate(across(everything(), ~replace_na(., "")))
  
  return(df_strata)
}