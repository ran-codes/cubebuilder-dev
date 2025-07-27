#' This function runs in two life cycles 1) raw -> int and 2) int -> final. It will automatically generate
#' codebook rows and values for any variable that has UCI or LCI in the dataset.  
#' 
#' Examples:
#'     active__codebook = raw__cdbks; stage = 'base'


compile_ci <- function(active__codebook, stage, i){
  
  # Setup -------------------------------------------------------------------
  { has_ci_vars = length(i$vec__var_ci) > 0
    if(!has_ci_vars) return(active_codebook)
  }
  
  # Base CI compile ---------------------------------------------------------
  if (stage == 'base'){

    { # Setup CI varaible codebook template -------------------------------------
      
      vec__domains = active__codebook %>%
        keep(~any(names(.x)=='domain')) %>%
        .[[1]] %>% pull(domain) %>%
        str_split(";") %>%
        unlist() %>%
        str_trim() %>%
        unique()
      
      if ("Mortality" %in% vec__domains){
        uci_var_def =   i$src$by_key %>% filter(key == 'freq_uci') %>% pull(value) %>% paste('{freq_uci}:',.)
        lci_var_def =   i$src$by_key %>% filter(key == 'freq_lci') %>% pull(value) %>% paste('{freq_lci}:',.)
        rm(vec__domains)
        
      } else {
        uci_var_def =   i$src$by_key %>% filter(key == 'uci') %>% pull(value) %>% paste('{uci}:',.)
        lci_var_def =   i$src$by_key %>% filter(key == 'lci') %>% pull(value) %>% paste('{lci}:',.)
        
      }
      
      df_ci_template_all  =  tibble(var_name = i$vec__var_ci) %>% 
        mutate(
          uci = glue("{var_name}_UCI"),
          lci = glue("{var_name}_LCI")
          
        ) %>% 
        pivot_longer(-var_name, names_to = 'ci', values_to ='var_name_ci')  %>% 
        left_join(active__codebook$by_var) 
      
      df_ci_template = df_ci_template_all %>% 
        filter(!var_name_ci%in%active__codebook$by_var$var_name)
      
      ## If already compiled then return
      if (nrow(df_ci_template)==0) return(active__codebook)
    }
    
   
    { # Op. CI metadata fields --------------------------------------------------
      df_ci_codebook = df_ci_template %>% 
        mutate(
          var_def = case_when(
            ci == 'uci' ~ uci_var_def,
            ci == 'lci' ~ lci_var_def),
          var_label = glue("{var_label} ({str_to_upper(ci)})")
          
        ) %>% 
        select(-c(var_name, ci)) %>% 
        rename(var_name = var_name_ci)
    }
  }
 
  

  
  { # Op. output codebook -----------------------------------------------------
    new_by_var = active__codebook$by_var %>% 
      bind_rows(df_ci_codebook) %>% 
      arrange(var_name)
    
    output__codebook = active__codebook
    output__codebook$by_var = new_by_var
    
    return(output__codebook)
  }
  
}
