#' takes in a dataset id and file name to return gh repo path. Assumes we are
#' int ref > dataset > index.R
#' 



get_gh_path = function(dataset_id, file){
  
  path = paste0('datasets/',dataset_id,'/', file)
  
  return(path) 
  
}
