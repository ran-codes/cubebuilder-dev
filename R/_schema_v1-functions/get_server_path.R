#' Get the UHC server path for a certain file depending on the datasetid
#'
#' This function is useful for generating path names to the UHC server. It will only work if
#' have uploaded your files to the UHC server `//files.drexel.edu/colleges/SOPH/Shared/UHC/Projects/Wellcome_Trust/Data Methods Core/Dashboards/FAIR Renovations`
#'
#' @param dataset_id_tmp (string)  dataset id.
#' @param folder (string) the type of folder you want to access. Possible options include:
#'                 - ''
#'                 - 'raw'
#'                 - 'clean'
#'                 - 'dbt'
#' @param file (string) the name of file you want to access.Note that if the specified folder is 'clean' we check 
#' for alist of accepted values as shown below. 
#'           -
#'"1-var_name.csv",'2-strata.csv',"3-linkages.csv",
#' @return a path to file you specified
#' @export
#'
#' @examples
#' get_server_path(dataset_id_tmp = "APSL1AD", file = "APSL1AD_06132022.csv")
#' get_server_path(dataset_id_tmp = "APSL1AD", file = "var_name.csv")
#' dataset_id_tmp = 'APSL1AD'; folder = 'clean'; file = 'data.csv'
#'
#'

# FUNCTIONS
get_server_path = function(dataset_id_tmp,folder,file = NA){
  server_base_dir = "//files.drexel.edu/colleges/SOPH/Shared/UHC/Projects/Wellcome_Trust/Data Methods Core/Dashboards/FAIR Renovations/"
  dbt_base_dir = "//files.drexel.edu/colleges/SOPH/Shared/UHC/Projects/Wellcome_Trust/Data Methods Core/Dashboards/dbt/v0/sources/"
  valid_clean_files = c("",
                        'data.csv',
                        "denormalized.csv","denormalized.parquet")
  path_dataset_folder = glue("{server_base_dir}{dataset_id_tmp}")
  
  # Dataset -----------------------------------------------------------------
  if (folder == ''){
    return(path_dataset_folder)
  }
  
  
  # Raw -------------------------------------------------------------------
  if (folder == 'raw'){
    ## Create paths 
    path_raw_folder = glue("{path_dataset_folder}/raw")
    path_raw_file = glue("{path_raw_folder}/{file}")
    
    ## Return
    if (file == ""){
      return(path_raw_folder)
    } else {
      return(path_raw_file)
    }
  }
  
  
  # Clean -------------------------------------------------------------------
  if (folder == 'clean'){
    ## Check if file name is valid
    valid_file_name = file%in%valid_clean_files
    if (!valid_file_name) {
      messsage("Invalid clean file name")
      stop()
    }
    
    ## Create paths 
    path_clean_folder = glue("{path_dataset_folder}/clean")
    path_clean_file = glue("{path_clean_folder}/{file}")
    
    ## Return
    if (file == ""){
      return(path_clean_folder)
    } else {
      return(path_clean_file)
    }
  }
  
  # DBT  --------------------------------------------------------------
  if (folder == 'dbt') {
    path__dbt_file = glue("{dbt_base_dir}{dataset_id_tmp}.parquet")
    return(path__dbt_file)
  }  
  
  
}
