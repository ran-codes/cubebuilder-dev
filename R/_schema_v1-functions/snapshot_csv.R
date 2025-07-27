#' this function will store codebooks in .xlsx in .json for a particular dataset or 
#' for all datasets
#' 
#' Example:
#'      folder = 'code/line-level-sources'
#'      path = 'clean/3-processed-humans/'

 
snapshot_csv = function(path = NULL, quiet = F ){
  
  ## setup
  pattern =  '.*'
  
  ## Find files in path
  csv_files = list.files(path, recursive = T, full.names = T) 
 
  ## Translate to JSON
  csv_files %>%
    walk( ~ {
      read_csv(.x) %>%
        jsonlite::write_json(path = str_replace(.x, 'csv', 'json'),
                             pretty = T)
      if (!quiet) {
        cli_alert("snapshot {.x} as .json")
      }
      
    })
  
 
 }
 