#' Takes in a codebook object and compiles the source and/or acknowledements jinja.
#' Note that function has two assumptions:
#'    Assumption 1: that source has a by_iso2_year relaitonship
#'    Assumption 2: Compilation acknolwedgements works only if it is in the same metadata table as 
#'                  source. ackenowledgments are just a copy of the source values.
#'    Assumption 3: this is raw -> base transition               
#'   
#' @param active__codebook: the active codebook to compile
#' @param i: dataset import object
#' 
#' Examples:
#'     active__codebook = raw__cdbks; stage = 'base'

compile_acknowledgement_jinja <- function(active__codebook, stage, i){
  
  
  { # Setup -------------------------------------------------------------------
    
    ## Table information
    raw_item = active__codebook %>% keep(~any(names(.x)=='acknowledgements')) 
    raw_table_name = names(raw_item)
    raw_table = raw_item[[1]]
    raw_table_pk = names(raw_table) %>% keep(~.x%in%i$xwalk_keys$keys)
    
    ## Jinja setup
    jinja_pattern = ifelse(stage == 'final',"\\{.*\\}","\\{\\{.*\\}\\}")
    raw_jinja = raw_table %>% filter(str_detect(acknowledgements,jinja_pattern)) %>% 
      separate_longer_delim(acknowledgements, delim = ";") %>% 
      mutate(acknowledgements = trimws(acknowledgements)) %>% 
      rename(key = acknowledgements) 
    list_raw_jinja = split(raw_jinja, raw_jinja$key)
    raw_non_jinja = raw_table %>% filter(!str_detect(acknowledgements,jinja_pattern))
    raw_jinja_pk = names(raw_jinja) %>% keep(~.x%in%i$xwalk_keys$keys) %>% discard(~.x=='dataset_id') 
    
    ## QC
    if (nrow(raw_jinja)==0|stage!='base')return(active__codebook)
  }
  
  { # Prep src crosswalk ------------------------------------------------------
    
    list_src_xwalk = list_raw_jinja %>% 
      map(function(raw_jinja_tmp){
        
        { ## Setup
          raw_key_tmp = raw_jinja_tmp$key %>% unique()
          keys_tmp =  c('key',raw_jinja_pk,'acknowledgement_value')
          src_item = i$src %>% 
            keep(~'acknowledgement_value'%in%names(.x)) %>% 
            keep(~raw_key_tmp[[1]]%in%unique(.x$key)) %>% 
            .[[1]]
          xwalk_src_raw = src_item %>% 
            filter(key%in%raw_jinja_tmp$key) %>% 
            mutate_at(vars(acknowledgement_value),
                      ~ paste(key,.x) %>% 
                        str_replace( "\\{\\{", "{") %>% 
                        str_replace( "\\}\\}", "}")) %>% 
            select(any_of(keys_tmp)) %>% 
            select(-any_of(c('public_value','source_value'))) %>% 
            distinct() %>% 
            unpack_year()
        }
        
        {# Process non-year src ----------------------------------------------------
          if (!'year'%in%names(xwalk_src_raw)) return(xwalk_src_raw)          
        }
        
        { ## Process year agnostic
          df__year_distinct =  xwalk_src_raw %>%
            group_by(iso2) %>%
            summarise(n_distinct_sources = n_distinct(acknowledgement_value))
          is_year_agnostic <- df__year_distinct %>%
            pull(n_distinct_sources) %>%
            all(. == 1)
          if (is_year_agnostic) return(
            xwalk_src_raw %>%
              select(-year) %>%
              distinct()) 
        }
        
        { ## Process year complex
          vec__simple_iso2 = df__year_distinct %>% filter(n_distinct_sources == 1) %>% pull(iso2)
          vec__complex_iso2 = df__year_distinct %>% filter(n_distinct_sources != 1) %>% pull(iso2)
          xwalk_src_simple = tibble(); xwalk_src_complex = tibble()
          if (length(vec__simple_iso2) > 0) {
            xwalk_src_simple = xwalk_src_raw %>%
              filter(iso2 %in% vec__simple_iso2) %>%
              select(-year) %>%
              distinct() } 
          if (length(vec__complex_iso2) > 0) {
            xwalk_src_complex = xwalk_src_raw %>%
              filter(iso2 %in% vec__complex_iso2)
          } 
          return(list(xwalk_src_simple, xwalk_src_complex))
        }
      })
  }
  
  { # Compile  ----------------------------------------------------------
    
    ## Compile long
    compiled_jinja_long = map2_df( 
      list_raw_jinja, list_src_xwalk,
      function(raw_jinja_tmp, xwalk_tmp){
        ## process single join
        if (is.tibble(xwalk_tmp)) { return(raw_jinja_tmp %>%left_join(xwalk_tmp)) }
        
        ## process multiple join
        df_merged = xwalk_tmp %>% 
          map_df(function(xwalk_tmp2){
            
            ## Setup
            df_jinja_tmp =  raw_jinja_tmp %>% filter(iso2%in%xwalk_tmp2$iso2)
            df_jinja_tmp_range = df_jinja_tmp %>%  filter(str_detect(year,'-')) 
            df_jinja_tmp_int = df_jinja_tmp %>%  filter(!str_detect(year,'-')) 
            has_year_range = nrow(df_jinja_tmp_range)>0
            has_year_int =  nrow(df_jinja_tmp_int)>0
            has_only_int = has_year_int && !has_year_range
            has_only_range = !has_year_int && has_year_range
            has_both = all(has_year_int, has_year_range)
            
            ## process year agnostic
            if (!'year'%in%names(df_jinja_tmp)) return(df_jinja_tmp %>% left_join(xwalk_tmp2) )
            
            ## process year integers only
            if (has_only_int) return(left_join(df_jinja_tmp,xwalk_tmp2))
            
            ## process year range only 
            if (has_only_range)  return( 
              df_merged_range %>% 
                group_by(var_name, iso2) %>% 
                group_split() %>% 
                map_df(~{ .x %>% 
                    arrange(desc(acknowledgement_value)) %>% 
                    slice(1) %>% 
                    select(-year) %>% 
                    rename(year = year_origin)
                })
            )
            
            ## process both year/range
            if (has_both) {
              return(
                df_merged_int %>% 
                  bind_rows(df_merged_range %>% 
                              group_by(var_name, iso2) %>% 
                              group_split() %>% 
                              map_df(~{ .x %>% 
                                  arrange(desc(acknowledgement_value)) %>% 
                                  slice(1) %>% 
                                  select(-year) %>% 
                                  rename(year = year_origin)
                              }))
              )
            }
          }
          )
      }) %>% 
      select(-key) %>% 
      rename(acknowledgement = acknowledgement_value)
    
    ## Return to original form
    compiled_jinja = compiled_jinja_long %>%
      group_by(across(c(-acknowledgement))) %>% 
      summarize(acknowledgements = str_c(acknowledgement, collapse = ";")) %>% 
      ungroup()
  }
  
  { # QC ----------------------------------------------------------------------
    
    df_missing_upstream = compiled_jinja %>% 
      filter(is.na(source)) %>% 
      left_join(
        raw_jinja %>% 
          select(any_of(c('dataset_id',  raw_jinja_pk, 'key')))) 
    if(nrow(df_missing_upstream) > 0){
      cli_alert_danger('Jinja keys missing dictionary values!')
      stop()
    }
    
    if (nrow(compiled_jinja) != nrow(raw_table)) cli_abort("Rows dropped during compilation pelase check!")
  }
  
  
  
  
  
  { # Return ------------------------------------------------------------------
    compiled__src_table = bind_rows(raw_non_jinja,compiled_jinja)%>%
      arrange(across(all_of(raw_table_pk)))
    
    compiled__codebook = active__codebook
    compiled__codebook[[raw_table_name]] = compiled__src_table
    return(compiled__codebook)
  }
  
}
