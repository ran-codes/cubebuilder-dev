#' This funciton will take in a list of codebooks and a particular xlsx. then check if the contents are different between the two. It
#' will rerutn TRUE if the content is dentical and FALSE if not identical
#' 
#' @param list_cdbk: (list) the codebook list you want to use to check the origin file against. 
#' @param xlsx_path: (string) the path to the .xslx codebook you are checking. 
#' 
#' Example:
#'   list_cdbk = template_sheets; xlsx_path = context$template_cdbk_path
#'   list_cdbk = list_current; xlsx_path = summary_file_path
#'


identical_cdbk_vs_xslx = function(list_cdbk, xlsx_path, context){
  
  
  { # setup -------------------------------------------------------------------
    if (!file.exists(xlsx_path)) return(F)
    current_content = import_salurbal_xslx_cdbk(xlsx_path, context)
  }
  
  { # macro checks -------------------------------------------------------------
    macro_check__identical_table_names = all(names(list_cdbk)==names(current_content))
    macro_identical = all(macro_check__identical_table_names)
    if (!macro_identical){return(F)}
  }
  
  
  { # check content diff ------------------------------------------------------
    
    identical = names(current_content) %>% 
      map_lgl(function(table_tmp){
             df_xlsx = current_content[[table_tmp]] %>%  mutate_all(~as.character(.x)) %>%  mutate_all(~replace_na(.x, replace ='' ))
             df_new = list_cdbk[[table_tmp]] %>%  mutate_all(~as.character(.x)) %>%  mutate_all(~replace_na(.x, replace ='' ))
             identical_tmp = identical(df_xlsx, df_new)
             if (!identical_tmp){ 
               cli_alert_warning("xlsx diff check: {table_tmp} sheet is not identical")
               print(df_xlsx)
               print(df_new)
                }
             return(identical_tmp)
           }) %>% 
      all()
    
    return(identical)
  }
  
}
