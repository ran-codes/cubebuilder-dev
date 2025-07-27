#' This function will take in int_codebooks and remove all pre-compiled jninja syntax
#' (e.g. single bracketed values) from codebooks
#' 
#' Example:
#' 
#'      active__codebook = int__codebooks; stage = 'final'


compile_final_jinja <-  function(active__codebook, stage, i){
  
  { # Setup -------------------------------------------------------------------
    
    potential_columns = c('source', 'public', 'acknowledgements')
    jinja_pattern = ifelse(stage == 'final',"\\{[^;]*\\}","\\{\\{.*\\}\\}")
    
    output__codebook = active__codebook
  }
  
  
  { # Remove pre-compiled syntax ----------------------------------------------

    potential_columns %>% 
      walk(function(column){
        # column = potential_columns[[2]]
        item = output__codebook %>% keep(~column%in%names(.x))
        table_name = names(item)
        raw_table = item[[1]]
        int_table = raw_table %>% 
          separate_wider_delim(!!sym(column), delim = ";", names_sep = "_", too_few = "align_start") %>% 
          mutate_at(vars(starts_with(!!column)), str_trim) %>% 
          mutate(across(contains(c(column)), ~str_replace_all(.x, "^\\{.*\\}$", NA_character_))) 
        
        if (column %in% c('source', "acknowledgements")){
          final_table = int_table %>%
            rowwise() %>%
            mutate(is_equal = n_distinct(c_across(starts_with(!!column))) == 1) %>%
            ungroup() %>%
            unite(!!sym(column), starts_with(!!column), sep = ";", remove = FALSE, na.rm = T) %>%
            mutate(!!column := ifelse(is_equal == TRUE, 
                                      !!sym(paste0(column, "_1")),  
                                      !!sym(column))) %>%
            mutate(!!column := !!sym(column) %>% 
                     str_replace_all("\\{(.*?)\\}", "(\\1)")) %>% 
            select(-c(starts_with(paste0(!!column, "_")), is_equal))  
        }
        
        if (column == 'public') {
          if (length(grep(colnames(int_table), pattern = column)) > 1){
            
            final_table = int_table %>%  
              mutate( across(contains("public_"),~str_remove_all(.x, jinja_pattern) %>% str_trim())  ) %>% 
              rowwise() %>%
              mutate(public = case_when(
                n_distinct(c_across(starts_with("public")), na.rm = T) == 1 ~ public_1,
                if_any(starts_with("public"), ~.x == "0") ~ "0",
                if_any(starts_with("public"), ~.x == "2") ~ "2",
                if_any(starts_with("public"), ~.x == "3") ~ "3",
                if_any(starts_with("public"), ~.x == "9") ~ "9",
              )) %>%
              ungroup() %>% 
              select(-c(starts_with("public_")))
            
            
            
          } else {
            
            # Logic for source, public, or acknowledgement column with one inputs
            final_table = int_table %>%
              rename(!!column := !!sym(paste0(column, "_1")))  %>%
              mutate(!!column := !!sym(column) %>% str_remove_all(jinja_pattern) %>% str_trim())
            
          }
        }
        
        output__codebook[[table_name]] <<- final_table  %>%
          mutate_all(~replace_na(., "")) 
      })
   
  }
  
  { # Return ------------------------------------------------------------------
    return(output__codebook)
  }
 
}