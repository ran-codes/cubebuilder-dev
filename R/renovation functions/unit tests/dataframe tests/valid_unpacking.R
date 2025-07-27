#' Check for Proper Unpacking of Potentially Packed Columns
#'
#' This function verifies that potentially packed columns (year and var_name_raw)
#' are properly tidied and don't contain separators (';' or '-').
#'
#' @param df A dataframe to be checked. Must contain columns 'dataset_id', 'year',
#'           and 'var_name_raw'.
#'
#' @return A logical value. TRUE if all checks pass (columns are properly unpacked),
#'         FALSE otherwise.
#'
#' @details
#' The function performs the following checks:
#' 1. Verifies that the 'year' column does not contain separators.
#'    - For most datasets, it checks for both ';' and '-'.
#'    - For specific datasets (LEMEDIAN_L1, LE_L25_POSTSAMP, LE_L25_SUMMARY,
#'      wescores, WomenPP, LEALESAMPLE), it only checks for ';'.
#' 2. Verifies that the 'var_name_raw' column does not contain the ';' separator.
#'
#' If any check fails, the function returns FALSE and issues a warning message
#' indicating which column failed the unpacking check.
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   dataset_id = c("LEMEDIAN_L1", "OtherDataset"),
#'   year = c("2020", "2021-2022"),
#'   var_name_raw = c("var1", "var2;var3")
#' )
#' result <- valid_unpacking(df)
#' print(result)  # Should return FALSE due to unpacked var_name_raw
#' }
#'
#' @import dplyr
#' @import stringr
#' @export

valid_unpacking = function(df){
  
  { # Setup -------------------------------------------------------------------

    ## Extract required metadata from parquet file
    dataset_id_tmp = df %>% 
      select(dataset_id) %>% 
      distinct() %>% 
      collect() %>% 
      pull(dataset_id)
    years_tmp = df %>% 
      select(year) %>% 
      distinct() %>% 
      collect() %>% 
      pull(year)
    var_name_raw_tmp = df %>% 
      select(var_name_raw) %>% 
      distinct() %>% 
      collect() %>% 
      pull(var_name_raw)
  }
  
  {# Test --------------------------------------------------------------------

    datasets_with_year_ranges = c('LEMEDIAN_L1','LE_L25_POSTSAMP','LE_L25_SUMMARY','wescores','WomenPP', "LEALESAMPLE")
    year_seperator =  ifelse(dataset_id_tmp%in%datasets_with_year_ranges, ";","-;") 
    valid_year_unpacking  = years_tmp %>% str_detect(year_seperator) %>%  !.
    valid_var_name_raw_unpacking = var_name_raw_tmp %>% str_detect(";") %>%   !.
    pass = all(valid_year_unpacking,valid_var_name_raw_unpacking)    
  }
    

  { # Return ------------------------------------------------------------------
    if (pass){
      cli_alert_info("Test passed: valid_unpacking()")
      return(TRUE)
    } else {
      
      if (!all(valid_year_unpacking)){ 
        warning("Test failed: valid_unpacking() - the year columns is not unpacked.")
        return(F)
      }
      
      if (!all(valid_var_name_raw_unpacking)){ 
        warning("Test failed: valid_unpacking() - the var_name_raw column is not unpacked.")
        return(F)
      }
      
      return(valid_unpacking)
    }
    
  }

  
  

}
