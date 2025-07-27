#' This script will hydrate our AZURE API folder each var_name (at this time just L1AD) will have two files data and 
#' codebook. We will use t he same logic as our submit handler but looped across variables. 
#' 
#' @param container_api: This can be either the Azure container to upload or a string containing the local api directory
#' @aliases              If it is a local API directory then only minified (first 20 rows) of data will be stored as json.
#' 
#' var_name_tmp = 'BECELEVATIONP25'
#' var_name_tmp = 'PRJPOP'
#' var_name_tmp = 'SVYMAM2YRS'
#' var_name_tmp = 'SVYHLTHFP'
#' df_data = cleaned_datasets
#' var_name_tmp = 'APSNO2GRIDPTS';
#' container_api = container_api_stage
#' container_api = local_api_dir
#' hydrateVariableAPI('APSNO2GRIDPTS',container_api_stage)




{# 1. Hydration function -----
  hydrateVariableAPI = function(df_data,var_name_tmp, container_api) {
    root = "C:/Users/ranli/Desktop/Git local/SALURBAL Dashboard Portal/data-pipeline"
    # 0.1 Prep data ----
    {
      ## Initialize req
      req = list()
      req$var_name = var_name_tmp
      req$attributes = xwalk_var_checkout %>% filter(var_name==var_name_tmp) %>% pull(var_name_nested) %>% unique()
      
      ## Subset cleaned_datasets + enforce censorship
      df_raw = df_data %>% 
        left_join(xwalk_iso2) %>% 
        filter(
          var_name_nested%in%req$attributes,
        ) %>% 
        ## Format numeric to four digits max
        mutate(value = ifelse(
          value_type == 'continuous',
          value %>% as.numeric %>% round(4),
          value))
      df_output_raw = df_raw %>%  filter( download == "1")
      df_output = df_output_raw %>% 
        select(iso2, id1 = salid1,city, var_name_nested, value, year) %>% 
        pivot_wider(names_from = var_name_nested, values_from = value) 
      
      ## Format column names to uppercase
      names(df_output) <- toupper(names(df_output))
      
      
    }
    
    # 0.2 Prep Codebook ----
    {
      ## Pull normal codebook entries (one per var_name)
      var_names = df_data %>% 
        filter(var_name_nested%in%req$attributes) %>% 
        pull(var_name) %>% 
        unique()
      normal_codebook_pull  = cleaned_codebooks %>% 
        filter(is.na(var_name_nested)) %>% 
        filter(var_name%in%var_names) %>% 
        select(domain, var_name, var_label, var_def, coding, units, 
               interpretation, source, notes, limitations, acknowledgment) %>% 
        distinct()
      template_normal = df_raw %>% 
        select(var_name, var_name_nested) %>% 
        filter(var_name%in%normal_codebook_pull$var_name) %>% 
        distinct()
      df_codebook_pull_normal = template_normal %>% 
        left_join(normal_codebook_pull) %>% 
        rename(sample = var_name_nested)
      
      ## Pull best codebook entries (multiple per var_name)
      df_codebook_pull_nested = cleaned_codebooks %>% 
        filter(!is.na(var_name_nested)) %>% 
        filter(var_name_nested%in%req$attributes) %>% 
        select(domain,var_name,sample = var_name_nested, var_label, var_def, coding, units, 
               interpretation, source, notes, limitations, acknowledgment) %>% 
        distinct()
      
      df_codebook_pull = bind_rows(df_codebook_pull_normal,df_codebook_pull_nested)
      
      ## Extract metadata from cleaned_dataset
      df_attributes = df_data %>% 
        filter(var_name_nested%in%req$attributes) %>% 
        select(var_name, var_name_base, sample = var_name_nested) %>% 
        distinct() %>% 
        left_join(xwalk_sample_label) %>% 
        distinct()
      
      
      ## Merge for final codebookk
      df_codebook = df_attributes %>% 
        left_join(df_codebook_pull) %>% 
        rowwise() %>% 
        mutate_at(vars(c(var_label, var_def)),
                  ~case_when(var_name == sample~.x ,
                             sample%in%df_codebook_pull_nested$sample~.x ,
                             TRUE~ paste0(glue("{.x} ({sample_label})")))  ) %>% 
        ungroup() %>% 
        select(-var_name_base, -var_name, -sample_label) %>% 
        select(domain, variable = sample, everything())
      
      ## format column names to uppercase
      names(df_codebook) <- toupper(names(df_codebook))
      
      ## Recode var_label and var_def
      df_codebook = df_codebook %>% 
        rename("LABEL"="VAR_LABEL",
               "DESCRIPTION"="VAR_DEF")
      
    }
    
    
    
    
    
    # 0.3 Upload to API ----
    if (typeof(container_api)=="character"){
      ## Upload to local datastore
      print(getwd())
      public_api = str_replace(container_api,'datastore','public')
      private_datastore = container_api
      
      #### Prep Data
      dataFile =  paste0(var_name_tmp,'_data','.csv')
      dataFileJson = paste0(var_name_tmp,'_data','.json')
      mini_df_output = df_output %>% slice(1:20)
      mini_json_output = toJSON(mini_df_output)
      
      #### Write Data
      write(mini_json_output, file = paste0(private_datastore,dataFileJson)) 
      fwrite(df_output, file =  paste0(public_api, dataFile)) 
      
      #### Prep Codebook
      codebookFile = paste0(var_name_tmp,'_codebook','.csv')
      codebookFileJson = paste0(var_name_tmp,'_codebook','.json')
      json_codebook = toJSON(df_codebook)
      
      #### Write Codebook
      write(json_codebook,paste0(private_datastore,codebookFileJson))
      fwrite(df_codebook, file =  paste0(public_api, codebookFile)) 
      
      
      
      print(paste("Sucessful local API Upload: ",var_name_tmp))
    } else  {
      ## Upload to Azure datastore
      
      
      ## Stage Full Files
      {
        ## Make temporary folder
        dirTmp = paste0( "staging/",var_name_tmp)
        dir.create(path = dirTmp)
        
        ## Data
        dataFile =  paste0(var_name_tmp,'_data','.csv')
        dataFileJson = paste0(var_name_tmp,'_data','.json')
        fwrite(df_output, file =  paste0(dirTmp,'/',dataFile))
        json_output = toJSON(df_output)
        write(json_output, file = paste0(dirTmp,'/',dataFileJson))
        
        ## Codebook
        codebookFile = paste0(var_name_tmp,'_codebook','.csv')
        codebookFileJson = paste0(var_name_tmp,'_codebook','.json')
        fwrite(df_codebook, file = paste0(dirTmp,'/',codebookFile))
        json_codebook = toJSON(df_codebook)
        write(json_codebook,paste0(dirTmp,'/',codebookFileJson))
      }
      
      
      ### Only upload data to API if there is uncensored data available
      setwd(dirTmp)
      if (nrow(df_output)>0){
        # storage_upload(container = container_api, src = dataFile, dest = dataFile)
        storage_upload(container = container_api, src = dataFileJson, dest = dataFileJson)
      }
      # storage_upload(container = container_api, src = codebookFile, dest = codebookFile)
      storage_upload(container = container_api, src = codebookFileJson, dest = codebookFileJson)
      setwd(root)
      
      ## Remove Tmp directory
      unlink(dirTmp, recursive = TRUE, force = TRUE)
      
      print(paste("Sucessful API Upload: ",var_name_tmp))
      
    }
    
    
  }
}




