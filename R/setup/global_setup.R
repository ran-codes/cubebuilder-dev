global_setup <- function(path_global_setup_function = NULL) {
  
  { # Setup -------------------------------------------------------------------
    
    
    ## Load required packages
    required_packages <- c("cli", "duckdb", "readxl", "jsonlite", "rjson", "xlsx", "data.table", 
                           "glue", "lubridate", "arrow", "dplyr", "tidyr", "purrr", "stringr", 
                           "ggplot2", "janitor", "readr", "tibble", 'whisker','tictoc','reactable',
                           'assertr','duckplyr','digest', 'here')
    if (!suppressWarnings(require(pacman, quietly = TRUE))) install.packages("pacman")
    pacman::p_load(char = required_packages)
    
    
    ## Options
    options(arrow.pull_as_vector = TRUE)
    
    
    ## Set up paths
    if (is.null(path_global_setup_function)) stop("Please provide the path_global_setup_function.")
    if (!file.exists(path_global_setup_function)) cli_abort("System could not find the specific setup funciton path. Please consider setting the working directory to current notebook then correctly specifying the path to the global setup function.")
    R_path <- here("R")
    
    ## Define dynamic source_parent function
    source_parent <<- function(function_name) {
      function_file <- paste0("^",function_name, '.R')
      etl_functions <- list.files(file.path(R_path, '_renovate'))
      R_path_local <- ifelse(function_file %in% etl_functions, 'R/_renovate/', R_path)
      function_path = list.files(path = R_path_local, all.files = TRUE,
                                 recursive = TRUE, full.names = TRUE,
                                 pattern = function_file)
      source(function_path)
    }
    
    ## Source all R functions files and collect sourced objects
    sourced_objects <- new.env()
    R_files <- list.files(path = R_path, all.files = TRUE,
                          recursive = TRUE, full.names = TRUE,
                          pattern = '\\.R$') %>%
      discard(~str_detect(.x, 'source_parent')) %>% 
      discard(~.x %in% c('D:/GitHub/cubebuilder-dev/R/setup/global_setup.R'))
    for (file in R_files) {
      tryCatch({
        source(file, local = sourced_objects)
      }, error = function(e) {
        warning(paste("Error sourcing file:", file, "\nError message:", e$message))
      })
    }
    
    ## Make sourced objects available in the current environment for export back to parent environment
    list2env(as.list(sourced_objects), envir = environment())
  }
  
  { # Get global context ------------------------------------------------------
    
    global_context <- get_global_context(root = here())
    
  }
  
  { # Return -----------------------------------------------------------------
    
    setup_object = list(
      global_context = global_context, ## context object 
      sourced_objects = as.list(sourced_objects),
      loaded_packages = required_packages
    )
    
    return(setup_object)
    
  }
  
}