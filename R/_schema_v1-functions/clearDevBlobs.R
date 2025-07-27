#' Blobs that are associated with development are tagged with `dev__`
#' This function will purge the specifeid container of all developemental
#' blobs.
#'  
#' `param1`: container = container_fullfilled_stage


clearDevBlobs = function(container){
  df_files = list_storage_files(container) %>% as_tibble()
  if (nrow(df_files>0)){
    df_files  %>% 
      filter(str_detect(name,"dev__")) %>% 
      pull(name) %>% 
      map(~delete_storage_file(container,.x, confirm = F))
  } 
  print(list_storage_files(container))
}

clearCsvBlobs = function(container){
  df_files = list_storage_files(container) %>% as_tibble()
  if (nrow(df_files>0)){
    df_files  %>% 
      filter(str_detect(name,".csv")) %>% 
      pull(name) %>% 
      map(~delete_storage_file(container,.x, confirm = F))
  } 
  print(list_storage_files(container))
}
