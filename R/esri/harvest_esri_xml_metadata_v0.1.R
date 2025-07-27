

# esri_xml_path = 'code/gis-repository/v1.0/raw/3-indvidual-layer-metadata-xml-files/SALURBAL_L1AD_NoSmallIslands_PublicIDs.xml'
# esri_xml_path = glue('{path$xml}/SALURBAL_L1AD_NoSmallIslands_PublicIDs.xml')
# esri_xml_path = glue('{path$xml}/{list__xml[[3]]}')

harvest_esri_xml_metadata = function(esri_xml_path){
  
  { # Setup -------------------------------------------------------------------

    xml_tmp = esri_xml_path %>% str_split("/") %>% unlist() %>% tail(n=1)
    gis_id_tmp = xml_tmp %>% str_remove_all('.xml')
    xml_root = xml2::read_xml(esri_xml_path, options = c('HUGE'))
    cli_alert_info("start harvesting of {xml_tmp}")
    
    i = lst()
  }
 
  
  # xml_structure(xml_root) 
  
  { ## DataElement ----------------------------------------------------
    xml_dataElement = xml_root %>% 
      xml_find_all('WorkspaceDefinition') %>% 
      xml_find_all('DatasetDefinitions') %>% 
      xml_find_all('DataElement')
    xml_field = xml_dataElement %>% 
      xml_find_all('Fields') %>% 
      xml_find_all('FieldArray') %>% 
      xml_find_all('Field')
    xml_extent = xml_dataElement  %>% 
      xml_find_all('Extent')
    # xml_dataElement %>% xml_structure()
    
    i$name = xml_dataElement %>% 
      xml_find_all('Name') %>% 
      xml_text
    i$datasetType = xml_dataElement %>% 
      xml_find_all('DatasetType') %>% 
      xml_text
    i$fieldName = xml_field %>% 
      xml_find_all('Name') %>% 
      xml_text()
    i$fieldType = xml_field %>% 
      xml_find_all('Type') %>% 
      xml_text()
    i$XMin = xml_extent %>% 
      xml_find_all('XMin') %>% 
      xml_text()
    i$YMin = xml_extent %>% 
      xml_find_all('YMin') %>% 
      xml_text()
    i$XMax = xml_extent %>% 
      xml_find_all('XMax') %>% 
      xml_text()
    i$YMax = xml_extent %>% 
      xml_find_all('YMax') %>% 
      xml_text()
  }
  
  { ## Second level Metadata ---------------------------------------------------
    xml_metadata =  xml_find_all(xml_root, ".//Metadata") %>% 
      xml_text() %>% 
      read_xml()
    xml_metadata
    
    { ### > ESRI ------------------------------------------------------------------
      metadata_esri = xml_find_all(xml_metadata, "Esri")  
      # metadata_esri %>%  xml_structure()
      
      i$CreaDate = xml_find_all(metadata_esri, "CreaDate")%>% xml_text()
      i$CreaTime = xml_find_all(metadata_esri, "CreaTime")  %>% xml_text()
      i$GeoCrdSys = xml_find_all(metadata_esri, "DataProperties") %>%  
        xml_find_all('coordRef')%>%  
        xml_find_all('geogcsn') %>%
        xml_text()
      i$SyncDate = xml_find_all(metadata_esri, "SyncDate")%>% xml_text()
      i$SyncTime = xml_find_all(metadata_esri, "SyncTime")%>% xml_text()
      i$ModDate = xml_find_all(metadata_esri, "ModDate")%>% xml_text()
    }    
    
    
    { ### > dataIdInfo ------------------------------------------------------------------
      metadata_dataIdInfo = xml_find_all(xml_metadata, "dataIdInfo")  
      # metadata_dataIdInfo %>%  xml_structure()
      
      i$label = xml_find_all(metadata_dataIdInfo, "idPurp") %>% xml_text()
      i$desc_html = xml_find_all(metadata_dataIdInfo, "idAbs") %>% xml_text()
      i$credit = xml_find_all(metadata_dataIdInfo, "idCredit")%>% xml_text()
      i$keywords = xml_find_all(metadata_dataIdInfo, "searchKeys") %>%  
        xml_find_all('keyword') %>% 
        xml_text()
    }
    
    { ### > mdLang ------------------------------------------------------------------
      metadata_mdLang = xml_find_all(xml_metadata, "mdLang")  
      # metadata_mdLang %>%  xml_structure()
    }
    
    { ### > distInfo ------------------------------------------------------------------
      metadata_distInfo = xml_find_all(xml_metadata, "distInfo")  
      # metadata_distInfo %>%  xml_structure()
      
      i$formatName  = metadata_distInfo %>% 
        xml_find_all('distFormat') %>% 
        xml_find_all('formatName') %>% 
        xml_text()
    }
    
    { ### > mdHrLv ------------------------------------------------------------------
      metadata_mdHrLv = xml_find_all(xml_metadata, "mdHrLv")  
      # metadata_mdHrLv %>%  xml_structure()
    }
    
    { ### > mdHrLvName ------------------------------------------------------------------
      # xml_find_all(xml_metadata, "mdHrLvName")  %>%  xml_structure()
    }
    
    { ### > refSysInfo ------------------------------------------------------------------
      # xml_find_all(xml_metadata, "refSysInfo")  %>%  xml_structure()
    }
    
    { ### > spatRepInfo ------------------------------------------------------------------
      # xml_find_all(xml_metadata, "spatRepInfo")  %>%  xml_structure()
    }
    
    { ### > spdoinfo ------------------------------------------------------------------
      # xml_find_all(xml_metadata, "spdoinfo")  %>%  xml_structure()
    }
    
    { ### > eainfo  ------------------------------------------------------------------
      # metadata_eainfo = xml_find_all(xml_metadata, "eainfo")  
    }
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
    df_return  = df_template%>% 
      pivot_wider(names_from = key,
                  values_from = value) %>% 
      mutate(gis_id = gis_id_tmp) %>% 
      select(gis_id, everything())    
    
    return(df_return)
  }
   
}
