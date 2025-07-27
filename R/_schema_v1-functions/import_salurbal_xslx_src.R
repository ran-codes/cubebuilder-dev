#' Will import src xlsx forun in /datasets/_src
#' 
#' Example:
#' xlsx_path = "datasets/_src/src__key.xlsx"
#  xlsx_path = "datasets/_src/src__census.xlsx"
#'  xlsx_path = "datasets/_src/src__population.xlsx"
#'  xlsx_path = "datasets/_src/src__vital_registration.xlsx"
#' xlsx_path =  "../../datasets/_templating_data/src__spatial_l3.xlsx"
#'  xlsx_path =  "../../datasets/_templating_data/context__key.xlsx"


import_salurbal_xslx_src = function(xlsx_path, src_schema){
  
  sheets = readxl::excel_sheets(xlsx_path)
  
  codebooks = sheets %>% 
    map(function(sheet){
      # sheet = sheets %>% pluck(1)
      ## Import all columns from individual sheets
      sheet_import_raw = xlsx::read.xlsx2( xlsx_path,
                                       sheetName = sheet) %>% 
        as_tibble() %>% 
        mutate_all(~as.character(.x)) %>% 
        filter(.[[1]] != '') %>% 
        select(-contains('X.'))
      
      ## QC for mislabled columns
      vec__invalid_src_cols = names(sheet_import_raw) %>% 
        discard(~.x%in%src_schema$columns)
      
      valid__src_cols = length(vec__invalid_src_cols) == 0 
      if (!valid__src_cols){
        vec__invalid_src_cols %>% 
          walk(~cli_alert("Invalid column name: {.x}"))
        cli_abort("Invalid src sheet for {unique(sheet_import_raw$key)}. please check!")
      }
  
      
      ## Return
      sheet_import = sheet_import_raw %>% 
        select(any_of(src_schema$columns))
      sheet_content = sheet_import 
      return(sheet_content)
      
    }) %>% 
    set_names(sheets)
  
  return(codebooks)
}

