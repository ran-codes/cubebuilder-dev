#' Clear all blobs in container will delete all blobs in a container

clearContainer = function(container){
  df_files = list_storage_files(container)
  if (nrow(df_files>0)){
    df_files$name %>% map(~delete_storage_file(container,.x, confirm = F))
  } 
  print(list_storage_files(container))
}