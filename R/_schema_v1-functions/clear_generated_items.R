#' This script will clear all pipeline generate things. This is used to clear things jsut to 
#' ensure production runs after pipeline modifications start from a clean slate. The types of items
#' to delete include:
#'    - "__codebook_by_var.csv"
#'    - "__codebook_by_var_iso2_year.csv"
#'    


clear_generated_items = function(){
  
  generated_items_regex = c(
    # '/1-var_name.csv',
    # '/2-strata.csv',
    '/schema.png',
    '/__codebook_by_var.csv',
    '/__codebook_by_var_iso2_year.csv'
    # '/base__codebook_by_var.csv',
    # '/base__codebook_by_var_iso2_year.csv'
  ) %>% 
    paste(collapse = '|')
  
  generated_items_path = tibble(file = list.files(path = 'datasets/', recursive = T,
                                                  full.names = T)) %>%
    filter(str_detect(file, generated_items_regex)) %>% 
    pull(file)
  
  generated_items_path %>% walk(~unlink(.x))
  
}