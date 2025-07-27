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
#'     active__codebook = raw__cdbks; value_type = 'source';
#'     active__codebook = raw__cdbks; value_type = 'public';
#'     active__codebook = raw__cdbks; value_type = 'acknowledgements';

compile_raw_to_base_jinja <- function(active__codebook, value_type, i){
  
  
  { # Setup -------------------------------------------------------------------
    
    ## Jinja Type setup
    cli_alert_info("Start {value_type} jinja compilation")
    vec__possible_value_types = c("public_value", "source_value", "acknowledgements_value")
    vec__unwanted_value_types = vec__possible_value_types %>% discard(~str_detect(.x, value_type))
    value_col_name = glue("{value_type}_value")
    
    ## Table information
    raw_item = active__codebook %>% keep(~any(names(.x) == value_type)) 
    raw_table_name = names(raw_item)
    raw_table = raw_item[[1]] 
    raw_table_pk = names(raw_table) %>% keep(~.x%in%i$xwalk_keys$keys)
  
    
    ## Jinja setup
    jinja_pattern = "\\{\\{.*\\}\\}"
    raw_jinja = raw_table %>% 
      filter(str_detect(!!sym(value_type),jinja_pattern)) %>% 
      tidyr::separate_longer_delim(!!sym(value_type), delim = ";") %>% 
      mutate(!!value_type := trimws(!!sym(value_type))) %>% 
      rename(key = !!sym(value_type)) 
    list_raw_jinja = split(raw_jinja, raw_jinja$key)
    raw_non_jinja = raw_table %>% filter(!str_detect(!!sym(value_type),jinja_pattern))
    raw_jinja_pk = names(raw_jinja) %>% keep(~.x%in%i$xwalk_keys$keys) %>% discard(~.x=='dataset_id') 
    
    ## QC
    if (nrow(raw_jinja)==0)return(active__codebook)
  }
  
  { # Prep src crosswalk ------------------------------------------------------
    
    list_src_xwalk = list_raw_jinja %>% 
      map(function(raw_jinja_tmp){
        
        { ## Setup      
          # raw_jinja_tmp = list_raw_jinja %>% pluck("{{population}}")
          raw_key_tmp = raw_jinja_tmp$key %>% unique()
          keys_tmp =  c('key',raw_jinja_pk, value_col_name)
          
          ## filter for src sheets  
          src_item = tibble()
          src_item_list = i$src %>% 
            ## that have the key
            keep(~raw_key_tmp%in%.x$key) %>% 
            map(~.x %>% 
                  filter(key==raw_key_tmp) %>% 
                  select(-any_of(vec__unwanted_value_types))) 
         
          
          ## If single sheet then return
          bool__src_single_sheet = length(src_item_list)==1
          if (bool__src_single_sheet)  src_item = src_item_list[[1]]
          
          ## If multiple sheet and all empty then return simplest
          bool__all_empty = src_item_list %>% 
            map_lgl(~all(.x %>% pull(!!value_col_name) =='')) %>% 
            all()
          if (!bool__src_single_sheet && bool__all_empty) src_item = src_item_list[[1]]
          
          ## Else If multiple and one has value then return that one
          if ((!bool__src_single_sheet && !bool__all_empty)) {
            src_item = src_item_list %>% 
              map(~.x %>% 
                    filter(!!sym(value_col_name)!='')) %>% 
              discard(~nrow(.x)==0) %>% 
              .[[1]]
          } 
          
          
          
          {##  QC src item: check if non-distinct by primary keys
            
            ### process special case of PRJT
            if (unique(src_item$key) == "{{population}}" && 
                'dataset_id'%in%names(src_item) &&
                !'dataset_id'%in%keys_tmp){
              src_item = src_item %>% filter(dataset_id == 'PRJT')
            }
            
            item_pk = names(src_item) %>% keep(~.x%in%keys_tmp) %>% 
              discard(~.x%in%c('key',value_col_name))
            
            df_distinct_test = src_item %>% 
              select(any_of(keys_tmp)) %>% 
              select(-any_of(vec__unwanted_value_types)) %>% 
              distinct() %>% 
              count(!!!syms(item_pk)) 
            
            if(any(df_distinct_test$n >1)) cli_abort("Source is not 1:1 with codebook. Please check!")
            
            }
          
          xwalk_src_raw = src_item %>% 
            filter(key%in%raw_jinja_tmp$key) %>% 
            mutate_at(vars(!!sym(value_col_name)),
                      ~ paste(key,.x) %>% 
                        str_replace( "\\{\\{", "{") %>% 
                        str_replace( "\\}\\}", "}")) %>% 
            select(any_of(keys_tmp)) %>% 
            select(-any_of(vec__unwanted_value_types)) %>% 
            distinct() %>% 
            unpack_year()
        }
        
        {# Process non-year src ----------------------------------------------------
          if (!'year'%in%names(xwalk_src_raw)) return(xwalk_src_raw)          
        }
        
        { ## Process year agnostic
          df__year_distinct =  xwalk_src_raw %>%
            group_by(iso2) %>%
            summarise(n_distinct_values = n_distinct(!!sym(value_col_name)))
          is_year_agnostic <- df__year_distinct %>%
            pull(n_distinct_values) %>%
            all(. == 1)
          if (is_year_agnostic) return(
            xwalk_src_raw %>%
              select(-year) %>%
              distinct()) 
        }
        
        { ## Process year complex
          vec__simple_iso2 = df__year_distinct %>% filter(n_distinct_values == 1) %>% pull(iso2)
          vec__complex_iso2 = df__year_distinct %>% filter(n_distinct_values != 1) %>% pull(iso2)
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
        # n = 4
        # raw_jinja_tmp = list_raw_jinja %>% pluck(n)
        # xwalk_tmp = list_src_xwalk %>% pluck(n)
        ## process single join
        if (is_tibble(xwalk_tmp)) { 
          return(raw_jinja_tmp %>%left_join(xwalk_tmp)) 
          }
        
        ## process multiple join
        df_merged = xwalk_tmp %>% 
          map_df(function(xwalk_tmp2){
            # xwalk_tmp2 = xwalk_tmp %>% pluck(1)
            ## Setup
            df_jinja_tmp =  raw_jinja_tmp %>% filter(iso2%in%xwalk_tmp2$iso2)
            df_jinja_tmp_range = df_jinja_tmp %>%  filter(str_detect(year,'-')) 
            df_jinja_tmp_int = df_jinja_tmp %>%  filter(!str_detect(year,'-')) 
            has_year_range = nrow(df_jinja_tmp_range)>0
            has_year_int =  nrow(df_jinja_tmp_int)>0
            # has_only_int = has_year_int && !has_year_range
            # has_only_range = !has_year_int && has_year_range
            # has_both = all(has_year_int, has_year_range)
            df_merge_int = tibble(); df_merge_range = tibble()
  
            
            ## process year agnostic
            if (!'year'%in%names(df_jinja_tmp)) return(df_jinja_tmp %>% left_join(xwalk_tmp2) )
            
            ## process year integers
            if (has_year_int) df_merge_int = left_join(df_jinja_tmp,xwalk_tmp2)
          
            ## process year range only 
            if (has_year_range) {
              df_merge_range = df_jinja_tmp_range %>% 
                unpack_year(keep_origin = T) %>% 
                left_join(xwalk_tmp2) %>% 
                group_by(var_name, iso2) %>% 
                group_split() %>% 
                map_df(~{ .x %>% 
                    arrange(desc(!!sym(value_col_name))) %>%
                    slice(1) %>% 
                    select(-year) %>% 
                    rename(year = year_origin)
                })
            } 
            
            ## Return objects
            df_merged_tmp = lst(df_merge_int, df_merge_range) %>% 
              discard(~nrow(.x)==0) %>% 
              bind_rows()
            return(df_merged_tmp)
            
          }
          )
      }) %>% 
      select(-key) %>%
      rename(!!value_type := !!sym(value_col_name))
    
    
    ## Return to original form
    compiled_jinja = compiled_jinja_long %>%
      group_by(across(-all_of(value_type))) %>%
      summarize(!!value_type := str_c(!!sym(value_type), collapse = ";")) %>%
      ungroup()
  }
  
  { # QC ----------------------------------------------------------------------
    
    
    ## Missing jinja-value pairs
    df_missing_upstream = compiled_jinja %>% 
      filter(is.na(!!sym(value_type))) %>% 
      left_join(
        raw_jinja %>% 
          select(any_of(c('dataset_id',  raw_jinja_pk, 'key')))) 
    if(nrow(df_missing_upstream) > 0) cli_abort('Jinja keys missing dictionary values!')
   
    ## Same number of rows start and end
    if (nrow(raw_jinja) != nrow(compiled_jinja_long)) cli_abort("Inconsistent row county post compilation: please check merges!")
  }
  
  
  
  
  
  { # Return ------------------------------------------------------------------
    compiled__src_table = bind_rows(raw_non_jinja,compiled_jinja)%>%
      arrange(across(all_of(raw_table_pk)))
    
    compiled__codebook = active__codebook
    compiled__codebook[[raw_table_name]] = compiled__src_table
    cli_alert_success("Success: compiled {value_type} jinja")
    return(compiled__codebook)
  }
  
}
