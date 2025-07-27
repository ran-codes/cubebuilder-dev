#' this functions takes a PMID and extract publicaiton meatdata from PUBMED's API
#' 
#' Example:
#'    pmcid_tmp = 'PMC10369015'
#'    pmcid_tmp = 'PMC10260576'
#'    pmcid_tmp = 'PMC6450446'
#'    pmcid_tmp = 'PMC6458229'
#'    pmcid_tmp = 'PMC10021609'

extract_pubmed_efetch_pmcid = function(pmcid_tmp){
  
    { # HTTP request ---------------------------------------------------------------------
      
      ## Op. endpoint
      pubmedcentral_api_root = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&id='
      endpoint_tmp =  glue("{pubmedcentral_api_root}{pmcid_tmp}")
    
      ## Make GET request
      risky_get <- function(endpoint_tmp){httr::GET(endpoint_tmp) }
      insistent_risky_get <- purrr::insistently(risky_get, 
                                                rate = rate_delay(pause = 3.5,max_times = 10), 
                                                quiet = F)
      response <-  insistent_risky_get(endpoint_tmp)
      
      ## Parse XML content
      xml_content <- httr::content(response, as = "text")
      xml_file <- xml2::read_xml(xml_content)  
      
      { ## Prep -------------------------------------------------------------------
        
        cli_alert('Start XML extract for PMCID: {pmcid_tmp}')
        i = lst()
        
        node__journalMeta = xml_file %>% xml2::xml_find_first(".//journal-meta")
        node__articleMeta = xml_file %>% xml2::xml_find_first(".//article-meta")
        nodes__ArticleIdList = node__articleMeta %>% xml2::xml_find_all(".//article-id")
        node__pubDate = node__articleMeta %>% xml2::xml_find_first('.//pub-date')
        node__contribGroup = node__articleMeta %>% xml2::xml_find_all(".//contrib-group") 
        nodes__contrib = node__contribGroup %>% xml2::xml_find_all(".//contrib")
        nodes__aff = node__articleMeta %>% xml2::xml_find_all(".//aff")
        
        ## Affiliations
        xwalk_aff = nodes__aff %>% 
          map_df(function(node_aff_tmp){
            # node_aff_tmp = nodes__aff[[1]]
            ## remove label
            aff_label_tmp = node_aff_tmp %>% xml2::xml_find_first('label') %>%  xml2::xml_text()
            xml2::xml_remove(xml2::xml_find_first(node_aff_tmp, "//label"))
            
            ## extract affiliation key-value
            aff_value_tmp = node_aff_tmp %>%  xml2::xml_text()
            aff_key_tmp = node_aff_tmp %>% xml2::xml_attr('id')
            
            tibble(
              aff = aff_value_tmp,
              aff_key = aff_key_tmp,
              aff_label = aff_label_tmp ) %>% 
              return()
          })
      }
    }
  
  { # Extract metadata ----------------------------------------------------
    
    
    { ## Simple Extractions -----------------------------------------------------------------
      i$journalTitle = node__journalMeta %>%  xml2::xml_find_first(".//journal-title-group//journal-title") %>%  xml2::xml_text()
      i$journalPublisher = node__journalMeta %>%  xml2::xml_find_first(".//publisher-name") %>%  xml2::xml_text()
      i$title = node__articleMeta %>% xml2::xml_find_first(".//article-title") %>% xml_text_clean()
      i$corrAuthor = node__articleMeta %>% xml2::xml_find_first('.//author-notes') %>% xml_text_clean()
      i$pubDay = node__pubDate %>% xml2::xml_find_first(".//day") %>% xml_text_clean()
      i$pubMonth = node__pubDate %>% xml2::xml_find_first(".//month") %>% xml_text_clean()
      i$pubYear = node__pubDate %>% xml2::xml_find_first(".//year") %>% xml_text_clean()
      i$summary =  node__articleMeta %>% xml2::xml_find_first(".//abstract//sec//p ") %>% xml_text_clean()
    }
    
    { ## Publication identifiers -------------------------------------------------
      nodes__ArticleIdList  %>% 
        walk(function(node_tmp){
          # node_tmp = nodes__ArticleIdList[[1]]
          type_tmp = node_tmp %>% xml2::xml_attr('pub-id-type')
          i[type_tmp] <<- node_tmp %>%  xml2::xml_text()
        })
    }
    
    { ## Affiliations ------------------------------------------------------------
      i$aff = lst()
      xwalk_aff %>% 
        group_by(row_number()) %>% 
        group_walk(function(row,i){
          i$aff[row$aff_label] <<- row$aff
        })
      
    }
    
    { ## Author Info -------------------------------------------------------------
      
      i$authorInfo = nodes__contrib %>% 
        map(function(node_tmp){
          # node_tmp = nodes__contrib[[3]]
          ii = lst(
            LastName = node_tmp %>% 
              xml2::xml_find_first('.//surname') %>% 
              xml_text_clean(),
            ForeInitials = node_tmp %>%
              xml2::xml_find_first('.//given-names') %>%
              xml_text_clean(),
            Affiliation =  node_tmp %>% 
              xml2::xml_find_all('.//xref  ') %>%
              xml_text_clean(),
            degree = node_tmp %>%  
              xml2::xml_find_all('.//degrees ') %>%
              xml_text_clean(concat = T) )
          return(ii)
        })
    }
    
    { ## Add utility flags -------------------------------------------------------
      
      i$etl$efetch_db = 'pmc'
      i$etl$pmid = pmcid_tmp
      
    }
  }
  
  { # Return ------------------------------------------------------------------

    
    Sys.sleep(3.5) ## this is for the API rate limit 3 request per 10 seconds. 
    
    cli_alert_success("Metadata harvested for PMCID: {pmcid_tmp}")
    
    return(i)    
  }
    
  
}


safely_extract_pubmed_efetch_pmcid = purrr::safely(extract_pubmed_efetch_pmcid)
