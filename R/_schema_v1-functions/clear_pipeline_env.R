#' clears project environemnt of all non-native pipeline objects. 
#' 

clear_pipeline_env = function(pipeline_objs) {
  
  ## get alien objects (non natives to pipeline)
  objs = ls(envir = globalenv())
  aliens = tibble(obj = objs) %>% filter(!obj%in%c(pipeline_objs,'objs')) %>% pull(obj)
  
  ## Delete from global env
  if (length(aliens)>0){
    rm(list =aliens, envir= globalenv())
    aliens %>% map(~message(glue("   Alien object deleted: {.x}")))
    message("Util: non-native objects cleared from global env.")
  } else {
    message(glue("Util: pipeline environment is clean!"))
  }
}
