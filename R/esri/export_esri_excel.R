#' This will export user friend codebooks in excell with many sheets. 

export_esri_excel = function(row_tmp, tibble_gis_metadata, path){
  

 
  
  
  { # setup -------------------------------------------------------------------

    # row_tmp  = df_need_process_excel %>% slice(1)
    
    i = as.list(row_tmp)
    file_name_tmp = row_tmp$api_file
    file_tmp = glue("{path$api_endpoints}/{file_name_tmp}")
    df_metadata_all = tibble_gis_metadata %>% filter(gis_id == row_tmp$gis_id)
    df_metadata = df_metadata_all %>% select(-df_fields)
    df_fields = df_metadata_all$df_fields[[1]]
    
  }
  
  { # summary sheet -----------------------------------------------------------------
    
    
      
    df__summary = df_metadata %>% 
      mutate(processed_by = glue("{individualName} ({positionName})")) %>% 
      select(`Version:` = version,
             `Codebook date:` = ingestDate,
             `Title:` = title, 
             `Abstract:` = abstract,
             `Purpose:` = purpose,
             `Keyswords:` = keywords,
             `Number of rows:` = geometricObjectCount,
             `Number of columns (variables):` = nrow(df_fields),
             raw_file_name = gis_id_raw,
             `Processed by:` = processed_by,
             `Metadata Standard:` = metadataStandardName,
             `Coordinate System:` = coordSys,
             `Suggested citation:` = credit,
             ) %>% 
      mutate_all(~as.character(.x)) %>% 
      rename_all(~str_to_title(.x)) %>% 
      mutate(r = row_number()) %>% 
      pivot_longer(cols = -r,
                   names_to = 'X1',
                   values_to = 'X2') %>% 
      select(-r)
      
    
  }
  
  { ## codebook sheet  -----------------------------------------------------------------
   
    df__codebook = df_fields %>% 
      select(
        `Field Name:` = field_name_tmp,
        `Field data type:` = field_type_tmp,
        `Field data width:` = field_width_tmp,
        `Field Definition:` = field_def_tmp
      )
  }
  
  { ## Compile   -----------------------------------------------------------------
    list_current = list(
      "Summary" = df__summary,
      "Codebook" = df__codebook
    )
  }
  
  { # Write  -------------------------------------------------------------------
    
    if (TRUE){
      
      { ## Setup xlsx -------------------------------------------------------------------
        wb = createWorkbook() 
        
        cs_text_bold <- CellStyle(wb) + 
          Font(wb, isBold=TRUE) +
          Border(color="black", 
                 position=c("BOTTOM", "LEFT", "TOP", "RIGHT"),
                 pen=c("BORDER_THIN"))+
          Alignment(wrapText=TRUE)
        
        cs_text <- CellStyle(wb) + 
          Border(color="black", 
                 position=c("BOTTOM", "LEFT", "TOP", "RIGHT"),
                 pen=c("BORDER_THIN"))+
          Alignment(wrapText=TRUE)
      }
      
      { ## Add Summary sheet -----------------------------------------------------------------
        sheet__summary  <- createSheet(wb, sheetName="Summary")
        
        
        setColumnWidth(sheet__summary, 1, 35)
        setColumnWidth(sheet__summary, 2, 50)
        
        addDataFrame(as.data.frame(df__summary), 
                     sheet__summary,
                     startRow=1, 
                     startColumn=1, 
                     row.names = F,
                     col.names = F,
                     colnamesStyle = cs_text_bold,
                     colStyle=list(`1`= cs_text_bold, `2`= cs_text))  
      }
      { ## Add Codebook Sheet-----------------------------------------------------------------
        sheet__codebook  <- createSheet(wb, sheetName="Codebook")
        x = 20
        y = 60
        setColumnWidth(sheet__codebook, 1, x)
        setColumnWidth(sheet__codebook, 2, x)
        setColumnWidth(sheet__codebook, 3, x)
        setColumnWidth(sheet__codebook, 4, x)
        setColumnWidth(sheet__codebook, 5, x)
        # setColumnWidth(sheet__codebook, 6, y)
        setColumnWidth(sheet__codebook, 7, x)
        setColumnWidth(sheet__codebook, 8, y)
        setColumnWidth(sheet__codebook, 9, y)
        
        addDataFrame(as.data.frame(df__codebook), 
                     sheet__codebook,
                     startRow=1, 
                     startColumn=1, 
                     row.names = F,
                     col.names = T,
                     colnamesStyle = cs_text_bold,
                     colStyle=list(`1`= cs_text,
                                   `2`= cs_text,
                                   `3`= cs_text,
                                   `4`= cs_text,
                                   `5`= cs_text,
                                   `6`= cs_text,
                                   `7`= cs_text,
                                   `8`= cs_text,
                                   `9`= cs_text))  
      } 
      
      
      {## Save xlsx -------------------------------------------------------------------
        saveWorkbook(wb,file_tmp) 
        cli_alert_success(paste("Wrote human codebooks:",file_tmp), .envir = globalenv())
      }
      
    }
    
  }
}

 