#' takes the results of prduction run and returns interpretable table and error messages.
#' 
#' Example
#'    prod_results = snapshot_results

reduce_prod_run_results = function(prod_results, all_funcs, env){
  
  log_id = as.numeric(Sys.time()) %>% str_sub(1,10)
  
  if (env == 'snapshot'){
    # Production -------------------------------------------------------------------
    { # Setup -------------------------------------------------------------------
      completed_runs = prod_results %>% keep(~!is.null(.x$result))
      completed_any = length(completed_runs)>0
      failed_runs = prod_results %>% keep(~!is.null(.x$error))
      failed_any = length(failed_runs)>0
    } 
    
    { # Successful Jobs -------------------------------------------------------------
      if (completed_any){
        df_success = completed_runs %>% 
          map_df(~.x$result) %>% 
          arrange(dataset)
      } else {df_success = tibble()}
    }
    
    
    { # Failed Jobs -------------------------------------------------------------
      if (failed_any){
        df_failed = failed_runs %>% 
          map('error') %>%
          compact() %>% 
          map2_df(.,names(.), ~{
            tibble(dataset = str_remove(.y, 'etl_safely_'),
                   cycle = get_etl_status(dataset)$status$cycle,
                   status = 'error',
                   error_msg = as.character(.x))}) %>% 
          arrange(dataset) 
      }else {df_failed = tibble()}
      
    }
    
    { # Return -------------------------------------------------------------
      if (completed_any) unique(df_success$dataset) %>% walk(~{ cli_alert_success(glue("  Renovated: {.x}"))})
      if (failed_any) unique(df_failed$dataset) %>% walk(~{ cli_alert_danger(glue("  FAILED JOB: {.x}"))})
      
      
      ## merge
      df_final_merged = bind_rows(df_success, df_failed) %>% 
        mutate(date = Sys.time()) 
      df_prod_cycles = df_final_merged %>% 
        filter(cycle%in%c('production','final_codebooks')) %>% 
        rowwise() %>% 
        mutate(func_id = glue("{dataset}_{version}"),
               func =  keep(all_funcs,~str_detect(.x,func_id)) %>% unlist()) %>% 
        ungroup()
      df_dev_cycles = df_final_merged %>% filter(!cycle%in%c('production','final_codebooks'))
      final = bind_rows(df_prod_cycles, df_dev_cycles) 
      log_path = glue("code/logs/{format(Sys.Date(), '%Y-%m-%d')}_snapshot_file_{log_id}.csv")
      write_csv(x = final, file = log_path)
      
      
      ## dataset level log 
      final_dataset_snapshot = final %>%
        count(dataset, version, cycle, date, status, error_msg, func_id, func) %>%
        select(-n) %>% 
        rename(log_date = date) %>% 
        arrange(version, cycle, dataset)
      dataset_log_path = glue("code/logs/{format(Sys.Date(), '%Y-%m-%d')}_snapshot_dataset_{log_id}.csv")
      
      write_csv(x = final_dataset_snapshot, file = dataset_log_path)
      
      return(
        lst(
          file_snapshot = final,
          dataset_snapshot = final_dataset_snapshot
        )
      )
    }
  }
  
  
  if (env == 'prod'){
    # Production -------------------------------------------------------------------
    { # Setup -------------------------------------------------------------------
      completed_runs = prod_results %>% keep(~!is.null(.x$result)) %>% keep(~.x$result$status=='done')
      completed_any = length(completed_runs)>0
      failed_runs = prod_results %>% keep(~!is.null(.x$error))
      failed_any = length(failed_runs)>0
    } 
    
    { # Successful Jobs -------------------------------------------------------------
      if (completed_any){
        df_success = completed_runs %>% 
          map_df(~.x$result) %>% 
          arrange(dataset)
      } else {df_success = tibble()}
    }
    
    
    { # Failed Jobs -------------------------------------------------------------
      if (failed_any){
        df_failed = failed_runs %>% 
          map('error') %>%
          compact() %>% 
          map2_df(.,names(.), ~{
            tibble(dataset = str_remove(.y, 'etl_safely_'),
                   cycle = get_etl_status(dataset)$status$cycle,
                   status = 'error',
                   error_msg = as.character(.x))}) %>% 
          arrange(dataset) 
      }else {df_failed = tibble()}
      
    }
    
    { # Return -------------------------------------------------------------
      if (completed_any) df_success$dataset %>% walk(~{ cli_alert_success(glue("  Renovated: {.x}"))})
      if (failed_any) df_failed$dataset %>% walk(~{ cli_alert_danger(glue("  FAILED JOB: {.x}"))})
      final = bind_rows(df_success, df_failed) %>% 
        mutate(date = Sys.time())
      log_path = glue("code/logs/{format(Sys.Date(), '%Y-%m-%d')}_prod_{log_id}.csv")
      write_csv(x = final, file = log_path)
      return(final)
    }
  }
  
  
  
}