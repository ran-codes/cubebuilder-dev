

# esri_xml_path = list__xml[1]
harvest_esri_xml_metadata_v1.0 = function(esri_xml_path){
  

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
 
  
  { ## contact ----------------------------------------------------

    i$individualName = xml_find_first(xml_file, ".//contact//individualName") %>% xml_text_clean()
    i$positionName = xml_find_first(xml_file, ".//contact//positionName") %>% xml_text_clean()
    i$role = xml_find_first(xml_file, ".//contact//CI_RoleCode ") %>% xml_text_clean()
    i$organisationName = xml_find_first(xml_file, ".//contact//organisationName") %>% xml_text_clean()
    
  }
  
  { # dateStamp ---------------------------------------------------------------

    i$dateStamp = xml_find_first(xml_file, ".//dateStamp//gco:Date") %>% xml_text_clean()
    
  }
  
  { # metadataStandardName ----------------------------------------------------

    i$metadataStandardName = xml_find_first(xml_file, ".//metadataStandardName//gco:CharacterString") %>% xml_text_clean()
    
  }
  
  { # spatialRepresentationInfo -----------------------------------------------
    spatial_info_node =  xml_find_first(xml_file, ".//spatialRepresentationInfo//MD_VectorSpatialRepresentation")
    i$MD_TopologyLevelCode = spatial_info_node %>% 
      xml_find_first(".//topologyLevel//MD_TopologyLevelCode ") %>% 
      xml_text_clean()
    i$MD_TopologyLevelCode_label = dict[i$MD_TopologyLevelCode] %>% unlist() %>% unname()
    
    i$MD_GeometricObjectTypeCode = spatial_info_node %>% 
      xml_find_first(".//geometricObjects//MD_GeometricObjects//geometricObjectType") %>% 
      xml_text_clean()
    i$geometricObjectCount = spatial_info_node %>% 
      xml_find_first(".//geometricObjects//MD_GeometricObjects//geometricObjectCount") %>% 
      xml_text_clean()
  }
  
  { # referenceSystemInfo -----------------------------------------------
    i$MD_TopologyLevelCode = xml_find_first(xml_file, ".//referenceSystemInfo//MD_ReferenceSystem//referenceSystemIdentifier//RS_Identifier") %>% 
      xml_text_clean() 
  }
  
  
  { # identificationInfo -----------------------------------------------
    id_node = xml_find_first(xml_file, ".//identificationInfo//MD_DataIdentification") 
    
    i$title = id_node %>% xml_find_first(".//citation//CI_Citation//title") %>% xml_text_clean()
    i$abstract = id_node %>% xml_find_first(".//abstract") %>% xml_text_clean()
    i$purpose = id_node %>% xml_find_first(".//purpose") %>% xml_text_clean()
    i$keywords =  id_node %>% xml_find_all(".//descriptiveKeywords") %>% xml_text_clean(concat = T)
    
  }
  
  
  
  { # extent -----------------------------------------------
    extent_node = xml_find_first(xml_file, ".//extent//EX_Extent//geographicElement") 
    
    i$westBoundLongitude = extent_node %>% xml_find_first(".//westBoundLongitude") %>% xml_text_clean()
    i$eastBoundLongitude = extent_node %>% xml_find_first(".//eastBoundLongitude") %>% xml_text_clean()
    i$southBoundLatitude = extent_node %>% xml_find_first(".//southBoundLatitude") %>% xml_text_clean()
    i$northBoundLatitude = extent_node %>% xml_find_first(".//northBoundLatitude") %>% xml_text_clean()
    
  }
  
  { # distributionInfo --------------------------------------------------------
   
     i$format = xml_find_first(xml_file, ".//distributionInfo//MD_Distribution") %>% xml_text_clean()
    
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
