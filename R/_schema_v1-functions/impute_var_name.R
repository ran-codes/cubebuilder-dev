#' Takes in a dataframe containing at least (var_name_san) and will reutrn a dataframe
#' with an addition collumn containing var_name. This process will detect if there is 
#' stratified var_name_san and append the appropriate var_name. Note any imputation via
#' this function will be flagged as `imputation = 1`'
#' 
#' 
#' Need to check for imputation by eye to double check logic in step 1.
#'
#' @param var_name_san the str to check
#' @param vector_special the vector of special var_names
#'
#' @return string of the appropriate var_name
#' @export
#'
#' @examples
#' match_special_var_name(
#'    var_name_san = "CNSLABPARTM",
#'    vector_special = c("CNSLABPART", "CNSMINHS",   "CNSMINPR" ,  "CNSMINUN" ,  "CNSST1517",  "CNSUNEMP"  )
#' )

# HELPERS FUNCTIONS
count_str_detections = function(pattern,vector){
  n_detections = stringr::str_detect(
    string = vector,
    pattern = pattern) %>% 
    sum()
  
  return(n_detections)
}

match_special_var_name = function(var_name_san,vector_special){
  # var_name_san = 'CNSST1517RAT'
  test_special_var_name = str_detect(string = var_name_san,
                                     pattern = vector_special)
  
  contains_special_var_name = any(test_special_var_name) 
  
  is_ratio = str_sub(var_name_san,-1L-2,-1L) == "RAT"

  if (!contains_special_var_name||is_ratio){
    return(var_name_san)
  } else {
    return(vector_special[which(test_special_var_name)])
  }
  
}

impute_var_name = function(df_intermediate){
  
  vector_raw = df_intermediate$var_name_raw
  ## Get a vector of repeated var_name_san. These like will be the real `var_name`
  vector_var_names = df_intermediate %>% 
    arrange(var_name_san) %>% 
    rowwise() %>% 
    mutate(n_detected = count_str_detections(
      pattern = var_name_san,
      vector = vector_raw
    )) %>% 
    filter(n_detected>1) %>% 
    pull(var_name_san)
  
  df_var_name = df_intermediate %>% 
    rowwise() %>% 
    mutate(
      var_name = match_special_var_name(
        var_name_san = var_name_san,
        vector_special = vector_var_names),
      imputation = ifelse(var_name%in%vector_var_names,'1','0')) %>% 
    ungroup() %>% 
    arrange(desc(imputation), var_name)

  return(df_var_name)
}
