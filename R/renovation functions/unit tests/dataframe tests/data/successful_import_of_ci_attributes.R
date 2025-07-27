#' this check sif there are confidence intervals int he data and if there are makes sure htese attributes are
#' propertly imported into df_data
#' 
#' Usage:
#'
#'   df %>% verify(successful_import_of_ci_attributes(.), error_fun = assertr::error_report)

successful_import_of_ci_attributes <- function(df, i) {
  
  ## Test
  vec__raw_ci_vars = i$raw_data %>% 
    names() %>% 
    str_to_upper() %>% 
    unique() %>% 
    keep(~str_detect(.x, '_LCI|_UCI'))%>% 
    keep(~.x %in% unique(df_data$var_name_raw)) 
  raw_has_ci = length(vec__raw_ci_vars) > 0
  if (!raw_has_ci) {
    valid_ci = T
  } else {
    df_data_has_ci = all(c('value_uci','value_lci')%in%names(df_data))
    valid_ci = raw_has_ci && df_data_has_ci
  }
  
  ## Test Failed
  if (!valid_ci){
    warning(glue("Invalid confidence intervals: confident interval columns are missing in df_data!"))
    return(F)
  }

  ## Test Passed
  return(TRUE)
}