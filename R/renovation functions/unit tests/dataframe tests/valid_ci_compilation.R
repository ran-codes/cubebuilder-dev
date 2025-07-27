valid_ci_compilation = function(df, i){
  
  needs_ci_metadata = length(i$vec__var_ci) > 0
  expected_ci_vars = c(glue("{i$vec__var_ci}_UCI"),glue("{i$vec__var_ci}_LCI"))
  ci_vars_tmp =   df %>% 
    pull(var_name) %>% unique() %>% 
    keep(~str_detect(.x,'_UCI|_LCI'))
  if (!needs_ci_metadata) valid_ci_compilation = length(ci_vars_tmp) == 0
  if (needs_ci_metadata) valid_ci_compilation = setequal(ci_vars_tmp, expected_ci_vars)
  
  return(valid_ci_compilation) 
  
  
}
