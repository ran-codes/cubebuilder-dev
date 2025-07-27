#' takes in a vector of strings with field/columnn names and returns a vector of strings minus 
#' all potential primary keys
#' 

remove_primary_keys = function(str){
  
  if (!is.null(str)){
    tibble(field = str) %>% 
      filter(!field%in%c('dataset_id',
                         'dataset_submission_date',
                         'var_name',
                         'var_name_raw',
                         'year',
                         'iso2',
                         'strata_id',
                         'salid1')) %>% 
      pull(field) %>% 
      return()
  }
  
}