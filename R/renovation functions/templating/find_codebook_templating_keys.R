find_df_jinja_keys <- function(df) {
  df %>%
    mutate(across(everything(), as.character)) %>%
    summarise(across(everything(), 
                     ~{
                       patterns <- str_extract_all(., "\\{\\{.*?\\}\\}")
                       unique_patterns <- unique(unlist(patterns))
                       unique_patterns <- unique_patterns[unique_patterns != ""]
                       if(length(unique_patterns) > 0) {
                         paste(unique_patterns, collapse = ", ")
                       } else {
                         NA_character_
                       }
                     })) %>%
    pivot_longer(everything(), names_to = "column", values_to = "patterns") %>%
    filter(!is.na(patterns)) %>% 
    pull(patterns) %>% 
    str_split(",") %>% 
    map(~str_trim(.)) 
}
find_codebook_templating_keys = function(active_codebook) {
  keys_found = active_codebook %>% 
    map(~find_df_jinja_keys(.x)) %>% 
    unlist() %>% 
    unique()
  
  if (is.null(keys_found)) {
    return(character(0))
  } else {
    return(keys_found)
  }
}
