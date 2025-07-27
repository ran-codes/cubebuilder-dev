#' this function will store codebooks in .xlsx in .json for a particular dataset or 
#' for all datasets
#'
#' @param dataset_id_tmp dataset_id
#' @param path specifies the relative directory to the specific file that you want to snapshot. For example 
#'             path = "../../_shared_storage/0_schema/templating_data.xlsx". If path is specified all other arguemnts are ignored.
#' @param quiet logical
#' @param folder folder
#' @return NULL
#' 
#' Example:
#'      folder = 'code/line-level-sources'


snapshot_excel = function(dataset_id_tmp = NULL, path = NULL, quiet = T, folder = "datasets"){
  
  ## setup
  pattern = case_when(
    folder == 'datasets' ~ 'codebook|src',
    folder == 'code/line-level-sources' ~ 'src',
    TRUE ~ '.*'
  ) 
  
  ## repository level snapshot
  excel_files = list.files(folder, recursive = T, full.names = T) %>%
    keep(~str_detect(.x, '.xlsx')) %>%
    keep( ~ str_detect(.x, pattern)) %>%
    discard( ~ str_detect(.x,  "\\(1\\)")) %>%
    discard( ~ str_detect(.x,  "\\(2\\)")) %>%
    discard( ~ str_detect(.x,  "\\(3\\)")) %>%
    discard( ~ str_detect(.x,  "\\(4\\)")) %>% 
    discard( ~ str_detect(.x, 'archive'))
    
  ## dataset specific snapshot
  if (!is.null(dataset_id_tmp)) {
    excel_files = excel_files %>% keep( ~ str_detect(.x, dataset_id_tmp))
  }
  
  ## file specific snapshot
  if  (!is.null(path)) {
    excel_files = path
  }
  
  excel_files %>%
    walk( ~ {
      import_salurbal_xslx_cdbk(.x) %>%
        jsonlite::write_json(path = str_replace(.x, 'xlsx', 'json'),
                             pretty = T)
      if (!quiet) {
        cli_alert("snapshot {.x} as .json")
      }
      
    })
  
 
 }
 