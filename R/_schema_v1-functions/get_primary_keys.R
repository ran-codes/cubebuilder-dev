#' takes  dataframe and reutrns what SLAURBAL primary keys are in this dataframe.
#' 


get_primary_keys = function(df, minus_var = F){
  
  primary_keys_all = df %>% 
    select(any_of(c('dataset_id',
                    'dataset_submission_date',
                    'var_name',
                    'var_name_raw',
                    'year',
                    'iso2',
                    'strata_id'))) %>% 
    names()
  
  
  if (minus_var){ 
    primary_keys = primary_keys_all %>% keep(~!.x%in%c("var_name",'var_name_raw'))
    return(primary_keys)
  } else {
    return(primary_keys_all)
  }
  
  
}