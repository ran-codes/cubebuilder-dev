#' this function will handle importing of salurbal codebook excell sheets. It will take a path of an xlsx
#' and return a lsit with each named item corerpsonding to a sheet in that excell sheet.
#' 
#' 
#' Example: 
#'      xlsx_path = context$raw_cdbk_path
#'      xlsx_path = xlsx_path
#'      xlsx_path = context$base_cdbk_path
#'      xlsx_path = context$template_cdbk_path
#'      xlsx_path = 'datasets//APS/intermediate/0-template__codebook.xlsx'
#'      xlsx_path =  '_shared_storage/0_schema/src.xlsx'
#'      xlsx_path = '_shared_storage/0_schema/src.xlsx'
#'      xlsx_path = raw_int


import_salurbal_xslx_cdbk = function(xlsx_path, context = NULL, src = F){
  
  ## Operationalize paths conditioned on notebook
  if (is.null(context) && src == T) {
    xlsx_path_clean = xlsx_path
  } else {
    # xlsx_path_clean = file.path(context$notebook_relative_root, xlsx_path)
    xlsx_path_clean = xlsx_path
  }
  
  ## Sheets
  sheets = excel_sheets(xlsx_path)
  generate_summary_sheets = c('Summary', 'Codebook')
  headless_sheets = c('Summary')
  
  codebooks = sheets %>%
    purrr::map(~{ 
      
      # .x = 'Summary'
      # .x = 'by_key_iso2'
      # .x = 'by_dataset'
      # .x = 'by_dataset_iso2'
      # .x = 'by_dataset_iso2_salid1'
      # .x = 'by_var_salid1'
      # .x = 'by_var'
      
      sheet_import_raw = xlsx::read.xlsx2( xlsx_path,
                                        sheetName = .x,
                                        head = ifelse(.x%in%headless_sheets,F,T)) %>% 
        as_tibble() %>% 
        mutate_all(~as.character(.x)) %>% 
        filter(.[[1]] != '') %>% 
        select(-any_of(c("X."))) %>% 
        select(-contains("X."))

      ## Detect redundancy due to excel merges
      if (.x!='Summary'){
        df_rename =  tibble(raw = names(sheet_import_raw)) %>% 
          mutate(cleaned = str_replace(raw, "\\..*", "")) %>% 
          group_by(cleaned) %>% 
          filter(str_detect(raw,".1") & !str_detect(raw,'salid1|l1_label') )%>% 
          ungroup()
        
        sheet_import = sheet_import_raw %>% 
          select(-df_rename$cleaned) %>%
          rename_with(~str_remove(., "\\.1$"))
      } else {
        sheet_import = sheet_import_raw
      }
         
    
      
      if (src == T){
        sheet_content = sheet_import
      } else if(.x=='Summary'){
        sheet_content = sheet_import
      } else if (.x=='Codebook'){
        sheet_content = sheet_import %>% 
          rename("Variable Label" = "Variable.Label",
                 "Variable Name" = "Variable.Name")
      } else if (.x=='source_by_iso2_year'){
        sheet_content = sheet_import %>% 
          select(source_key, iso2, year, source_value) %>% 
          filter(source_key!='')
        
      } else if (.x=='source'){
        sheet_content = sheet_import %>% 
          select(source_key, source_value) %>% 
          filter(source_key!='')
      } else if (is.null(context)){
        sheet_content = sheet_import  
      } else {
        vec__other_accepted_columns = c('salid1','l1_label')
        vec__other_accepted_columns = c('salid1','l1_label','source_URL', 'source_terms_of_use_URL')
        sheet_content = sheet_import  %>% 
          select( names(sheet_import) %>%
                    keep(~.x%in%c(context$df_admin_layer_schema$name,vec__other_accepted_columns)) )
        
      }
      
      return(sheet_content)
      
    }) %>% 
    set_names(sheets)
  
  return(codebooks)
}
