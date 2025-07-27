#' Utility funciton taht pulls dataset_id from metadata source path
#' 
#' Example:
#'     path = '//files.drexel.edu/colleges/SOPH/Shared/UHC/Projects/Wellcome_Trust/Data Methods Core/Dashboards/dbt/v1.0/sources/metadata/APS_metadata_by_var.parquet'
#'     path = 'line_level_health_care_child_metadata_by_iso2_year.parquet'
#'     path = 'BTH_v1.0_metadata_by_var_strata.parquet'


get_dataset_from_metadata_path <- function(path, etl){
  
  path %>% 
    str_remove(etl$dbt_metadata_path) %>%
    str_remove(".parquet") %>% 
    str_remove("_metadata_") %>% 
    str_remove("by_dataset_iso2_year") %>%
    str_remove("by_dataset_var") %>%
    str_remove("by_dataset") %>% 
    str_remove("by_var_iso2_year") %>%
    str_remove("by_var_strata") %>%
    str_remove("by_var") %>%
    str_remove("by_iso2_year") %>%
    str_remove("/")
  
}