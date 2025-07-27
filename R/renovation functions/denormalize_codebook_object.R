#'
#'
#' Example
#' 
#'    codebook_object = templates; template = T; raw = F
#'    codebook_object = raw_codebook_object; template = F; raw = T
#'    codebook_object = templates[1:3]; template = T; raw = F
#'    codebook_object = templates; template = T; raw = F
#'    codebook_object = intermediate_codebook_object; template = F; raw = F

denormalize_codebook_object = function(codebook_object, context, template = F, raw = F){
  
  { # Setup ------------------------------------------------------------------
    
    
    ## Always ignore by_observation_id sheet
    codebook_object$by_observation_id = NULL

    ## Variable subset
    all_vars_in_data_cube = context$final_data_cube %>% 
      select(var_name) %>% 
      distinct() %>% 
      collect() %>% 
      pull(var_name)
    all_vars_in_codebook_object = codebook_object %>% 
      map(~if('var_name'%in%names(.x))  return(unique(.x$var_name))) %>% 
      unlist() %>% 
      unname() %>% 
      unique()
    vec__unexpected_vars = setdiff(all_vars_in_codebook_object, all_vars_in_data_cube)
    if (length(vec__unexpected_vars) > 1) cli_abort("Unexpected variables in codebook but not in data: {vec__unexpected_vars}")
  }
  

  { # By Sheet  ---------------------------------------------------------------

    { # Metadata Cube  ------------
      metadata_cubes = codebook_object %>% 
        map(~{
          
          ## Setup up objects keys 
          local_keys = c(context$vec__admin_metadata_composite_keys, 'original_linkage')
          df_codebook_tmp =  unpack_string_column(.x,list(context$vec__admin_metadata_composite_keys))
          keys_tmp = names(df_codebook_tmp) %>% keep(~.x%in%local_keys) %>% sort() %>% list()
          
          ## Denormalize
          df_metadata_wide = context$metadata_cube_key_template %>% 
            collect() %>% 
            filter(var_name%in%all_vars_in_codebook_object) %>% 
            left_join(df_codebook_tmp) %>% 
            mutate(original_linkage = keys_tmp)
          
        })
    }
    
    
    { #  Tidy Metadata  ------------
      metadata_tidy = metadata_cubes %>% 
        map(~{
          
          ## Setup up objects keys
          local_keys = c(context$vec__admin_metadata_composite_keys, 'original_linkage','var_name')
          
          ## Tidy  metadata cube by  column
          df_metadata_tidy = .x %>% 
            pivot_longer(cols = -all_of(local_keys), 
                         names_to = 'column', values_to = 'value') %>% 
            filter(value != '')
          if (template){
            df_metadata_tidy = .x %>% 
              pivot_longer(cols = -all_of(local_keys), 
                           names_to = 'column', values_to = 'value') 
          }
          return(df_metadata_tidy)
        }) 
      
    }
    
    {  # Render Templating Data  ------------
      metadata_tidy_rendered = metadata_tidy %>% 
        map(~{
          
          ## Subset rows that need to be rendered   
          tidy_metadata_sheet = .x  # .x = metadata_tidy[[2]]
          if (raw) {
            ## Dont render in raw codebook stage
            to_render = tidy_metadata_sheet %>% slice(0)
            no_rendering_needed = tidy_metadata_sheet %>% 
              mutate(value_rendered = value)
          } else {
            ## Only render during int -> prod
            to_render = filter(tidy_metadata_sheet, str_detect(value, "\\{\\{"))  
            no_rendering_needed = tidy_metadata_sheet %>% 
              filter(!str_detect(value, "\\{\\{")) %>% 
              mutate(value_rendered = value)
          } 
          
          ## Render
          if (nrow(to_render) == 0) rendered_results_validated = to_render
          if (nrow(to_render) > 0) {
            rendered_results = to_render %>% 
              group_by(original_linkage) %>%
              group_map(~{
                
                ## Setup
                ## .x = to_render; .y = to_render
                to_render_tmp = .x  %>% mutate(original_linkage = .y$original_linkage)
                original_linkages_keys = unique(to_render_tmp$original_linkage) %>% unlist()
                
                if (!'original_linkage'%in%names(to_render_tmp)) cli_abort('original_linkage not in to_render_tmp')
                
                ## Optimized rendering
                value_rendered_tmp = to_render_tmp %>%
                  select(all_of(c('var_name',  'column', 'value', 'original_linkage', original_linkages_keys))) %>%
                  distinct() %>%
                  group_by(row_number()) %>%
                  group_map(~ render_metadata_cell(.x, context)) %>%
                  bind_rows()
                
                ## Merging in rendered value_rendered + QC
                render_results_tmp = to_render_tmp %>%
                  left_join(value_rendered_tmp) %>%
                  verify(composite_key_uniqueness(., context))  
                return(render_results_tmp)
                
              })  %>%
              bind_rows()
            
            ## Validate
            rendered_results_validated = rendered_results %>%
              verify(full_referential_integrity(., to_render, context))
            if (nrow(rendered_results) > 0) {
              df_qc = rendered_results %>% 
                filter(value_rendered %>% str_detect("\\{\\{"))
              
              df_result = df_qc%>% 
                count(iso2,column) %>% 
                mutate(note = 'Missing template data by iso2, column (reduced granularity)') %>% 
                arrange(iso2) 
              
              if (nrow(df_result) > 0) {
                print(df_result, n = Inf)
                cli_abort("Missing template data by iso2, column (reduced granularity)")
              }
            }
          }
          
          ## Return
          df_result = bind_rows(rendered_results_validated, no_rendering_needed) %>% 
            arrange(var_name,iso2, strata_id, geo, year)
          return(df_result)
        }) 
    }
  }

  
  { # Compiled ----------------------------------------------------------------
   
    { # Compile Tidy Metadata -----------------------------------------------------------------
      
      ## Handle redundant var_name_raw columns
      df_metadata_compiled_raw = metadata_tidy_rendered %>% 
        bind_rows() 
      df_var_name_raw = df_metadata_compiled_raw %>% 
        filter(column == 'var_name_raw') %>% 
        select(-original_linkage) %>% 
        distinct()
      
      ## Test
      df_metadata_compiled = df_metadata_compiled_raw %>% 
        filter(column != 'var_name_raw') %>%  
        bind_rows(df_var_name_raw) %>%
        verify(composite_key_uniqueness(., context)) %>% 
        select(c(context$vec__admin_metadata_composite_keys,'column', 'value_rendered')) 
      
    }
    
    { # Generate metadata cube --------------------------------------------------
      
      metadata_wide = df_metadata_compiled  %>% 
        pivot_wider(names_from = column, values_from = value_rendered) 
      
      
      ## Initialize any columns missing
      new_columns <- setdiff(context$template__linkage$field, names(metadata_wide))
      for (col in new_columns) {
        if (!(col %in% names(metadata_wide))) {
          metadata_wide[[col]] <- ''
        }
      } 
      metadata_wide = metadata_wide %>% rename(public_intermediate = public)
      
      ## Summarize public if multiple values
      xwalk_public_final = metadata_wide %>% 
        select(public_intermediate) %>% 
        distinct() %>% 
        rowwise() %>% 
        mutate(public =  public_intermediate  %>%
                 str_extract_all("\\d+") %>%
                 unlist() %>%
                 as.numeric() %>%
                 {if(length(.) == 0) '' 
                   else if(length(.) == 1) as.character(.)
                   else if(all(. == 1)) '1'
                   else '0'
                 }
               ) %>% 
        ungroup()
      
      
      ## final processing
      metadata_cube = metadata_wide %>% 
        left_join(xwalk_public_final) %>%
        select(-public_intermediate) %>% 
        verify(full_referential_integrity(., metadata_wide, context)) %>% 
        mutate(version = context$version_tmp) %>%
        mutate(across(everything(), as.character))
    }
    
  }

  return(metadata_cube)
  
}