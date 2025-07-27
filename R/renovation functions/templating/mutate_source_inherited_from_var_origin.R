## Utility: Checks if a `var_name` is in production either in current codebook or in datawarehouse
is_salurbal_production_variable = function(var_name, metadata_cube, local_context){

  boolean__is_production_variable = any(
    var_name%in%metadata_cube$var_name,   ## Case 1: in current active codebook 
    var_name%in%local_context$df__prod_variables$var_name  ## Case 2: in previous codebooks
  ) 
  
  if (!boolean__is_production_variable){
    cli_abort("{var_name} is specified as an origin variable but is not a production variable!")
  }
  
  return(boolean__is_production_variable)
}

## Utility: Takes a `var_name` and returns the `var_label` from the metadata cube (optionall to inlucde Portal URL)
get_var_label = function(var_name_tmp, metadata_cube, local_context, with_portal_url = F){

  ## Diagnose where to pull metadata from
  case = case_when(
    var_name_tmp%in%metadata_cube$var_name ~ 'In Current',  
    var_name_tmp%in%local_context$df__prod_variables$var_name ~ 'In Datawarehouse',
    TRUE ~ "ERROR"
  ) 
  if (case == "ERROR") cli_abort("Specified variable is not in production - please verify upstream logic!")
  
  ## Case 1: in current active codebook 
  if (case == 'In Current'){
    var_label_tmp = metadata_cube %>% 
      filter(var_name == var_name_tmp) %>% 
      pull(var_label) %>% 
      unique() %>% 
      return()
  }
  
  ## Case 2: in previous codebooks
  if (case == 'In Datawarehouse'){
    var_label_tmp = local_context$df__prod_variables %>% 
      filter(var_name == var_name_tmp) %>% 
      pull(var_label) %>% 
      unique() %>% 
      return()
  }
  
  
  ## Return conditional on if requested URL or not
  if (with_portal_url){
    return(glue("[{var_label_tmp}](https://data.lacurbanhealth.org/data/catalog/{var_name_tmp})"))
  } else {
    return(var_label_tmp)
  }
}

## Utility. Takes a metadata cube row and creates a source link from the origin variables if possible. returns a mutated row.
create_source_links_from_origin_vars = function(row, metadata_cube, local_context){
  # row = df_qualify_for_inheritance %>% slice(1)
  
  ### Stop if already has a source
  if (non_missing_value(row$source)) return(row)
  
  ### Get a list of origin variables
  vec__origin_vars = row %>% 
    pull(variable_origin) %>% 
    str_split(";") %>% 
    unlist() %>% 
    str_trim()
  
  ### Verify origin variables are valid
  valid_origin_vars = vec__origin_vars %>% 
    map_lgl(~is_salurbal_production_variable(.x, metadata_cube, local_context)) %>% 
    all()
  
  ### Operationalize links to portal
  result_origin_links = vec__origin_vars %>% 
    map_chr(~.x %>%  get_var_label(metadata_cube, local_context, with_portal_url = T)) %>% 
    paste(collapse = "; ")
  
  ## Operationalize inherited source. 
  source_inheritance_prefix = "This variable was built using several other SALURBAL variables. Please refer to the following links for information about those individually:"
  source_inheritance = paste(source_inheritance_prefix, result_origin_links)
  
  ## Return modified row
  row$source = source_inheritance
  return(row)
  
}


##' Primary function: takes a metadata cube and applies source inheritance logic to rowise to appropriate rows. Returns the a consistent mutate metadata cube
##'  Example
##'     metadata_cube = intermediate_metadata_cube
mutate_source_inherited_from_var_origin = function(metadata_cube, local_context){
  
  ## Subset dataframe to those that meet inheritance criteria
  df_qualify_for_inheritance = metadata_cube %>% 
    filter(source==''|is.na(source)) %>% 
    filter(variable_origin != 'primary') 
  df_unselected_for_inheritance = metadata_cube %>%
    anti_join(df_qualify_for_inheritance)
  

  ## Exit if not needed
  if (nrow(df_qualify_for_inheritance) == 0) return(metadata_cube)

  
  ## If needs Inheritance
  if (nrow(df_qualify_for_inheritance > 0)){
    
    ## Process Inheritance
    df_source_inheritance = df_qualify_for_inheritance %>% 
      group_by(row_number()) %>% 
      group_map(~create_source_links_from_origin_vars(.x, metadata_cube, local_context)) %>% 
      bind_rows() %>% 
      verify(full_referential_integrity(., df_qualify_for_inheritance, local_context))
    
    ## Bind back to original dataframe
    result = bind_rows(df_source_inheritance, df_unselected_for_inheritance) %>% 
      verify(full_referential_integrity(., metadata_cube, local_context))
    return(result)
  }
      
}
