

# esri_xml_path = list__shp_xml[1]

harvest_esri_xml_metadata_v1.0.1_shp_xml = function(esri_xml_path){
  

  { # Setup -------------------------------------------------------------------

    xml_tmp = esri_xml_path %>% str_split("/") %>% unlist() %>% tail(n=1)
    gis_id_tmp = xml_tmp %>% str_remove_all('.xml')
    
    ## Read XML file
    xml_file  = esri_xml_path %>% 
      xml2::read_xml(options = c('HUGE')) %>% 
      xml_ns_strip()
    
    ## Dictionary
    dict = lst(
      geometryOnly = 'geometry objects without any additional structure which describes topology'
    )
    
    cli_alert_info("start harvesting of {xml_tmp}")
    i = lst()
  }
 
  
  
  
 
  
  { # df_fields ------------------------------------------------------------------
    
    field_nodes = xml_file %>% xml_find_all(".//detailed//attr")
    i$df_fields = field_nodes %>% 
      map_df(~{
        # .x = field_nodes[[1]]
        tibble(
          field_name_tmp = .x %>% xml_find_first(".//attrlabl") %>% xml_text_clean(concat = F),
          field_type_tmp = .x %>% xml_find_first(".//attrtype") %>% xml_text_clean(concat = F),
          field_width_tmp = .x %>% xml_find_first(".//attwidth") %>% xml_text_clean(concat = F),
          field_def_tmp = .x %>% xml_find_first(".//attrdef") %>% xml_text_clean(concat = F),
        )
      }) 
    
  }
  
  
  { # ETC  ------------------------------------------------------------------

    i$credit = xml_file %>% xml_find_first(".//dataIdInfo//idCredit") %>% xml_text_clean()
    i$extentDesc =  xml_file %>% xml_find_first(".//dataExt//exDesc") %>% xml_text_clean()
    
  }
  
  { # Ref + Coord System ------------------------------------------------------------------
    
    ## Coord system
    i$coordSys = xml_find_first(xml_file, ".//coordRef//geogcsn") %>% xml_text_clean()
    
    # ## Ref
    i$RefSystemCode = xml_file %>% xml_find_first(".//refSysID//identCode ") %>% xml_attr('code')
    i$RefSystemId = xml_file %>% xml_find_first(".//refSysID//idCodeSpace") %>% xml_text_clean()
    i$RefSystemVersiopn = xml_file %>% xml_find_first(".//refSysID//idVersion") %>% xml_text_clean()

  }
  
  { # Op. dataframe -----------------------------------------------------------

    df_template = tibble()
    names(i) %>% 
      walk(function(metadata_key){
        row_tmp = tibble(
          key = metadata_key,
          value = i[metadata_key]
        )
        df_template <<- df_template %>% 
          bind_rows(row_tmp )
      })
    
    vec__single_value_columns = names(i)[unlist(i %>% map(~{length(.x)==1}))]
    
    df_return  = df_template%>% 
      pivot_wider(names_from = key,
                  values_from = value) %>% 
      mutate(gis_id = gis_id_tmp) %>% 
      mutate_at(vars(vec__single_value_columns), 
                ~unlist(.x) ) %>% 
      select(gis_id, everything())    
    
  
    
    return(df_return)
  }
   
}
