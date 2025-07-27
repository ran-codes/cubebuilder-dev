#' Checks all columns within a dataframe are all 'character' type.
#' This is an assumption we make in all structures to ensure standard parsing downstream into JSON
#' 
#' Usage:
#'    df %>%  
#'       verify(columns_all_character(.), error_fun = assertr::error_report)

columns_all_character <- function(df) {
  
  ## Test
  chr_columns = df %>% select_if(is.character) %>% names() 
  valid_chr_type = ncol(df) == length(chr_columns)
     
  
      
  ## Test Failed
  if (!valid_chr_type){
    num_columns = df %>% select_if(is.numeric) %>% names() 
    bool_columns = df_data %>% select_if(is.logical) %>% names() 
    warning(glue("`valid_chr_type` error: {paste(c(num_columns,bool_columns), collapse = ', ')} are not character"))
    return(F)
  }
  
  # All checks passed
  return(TRUE)
}