#' this functions takes a PMID and extract publicaiton meatdata from PUBMED's API
#' 
#' Example:
#'    pmid_tmp = '31666140'
#'    pmid_tmp = '35932016'
 
extract_pubmed_efetch_pmid = function(pmid_tmp){
  
    { # HTTP request ---------------------------------------------------------------------
      
      ## Op. endpoint
      pubmed_api_root = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id='
      endpoint_tmp =  glue("{pubmed_api_root}{pmid_tmp}")
      
      ## Make GET request
      risky_get <- function(endpoint_tmp){httr::GET(endpoint_tmp) }
      insistent_risky_get <- purrr::insistently(risky_get, 
                                                rate = rate_delay(pause = 3.5,max_times = 10), 
                                                quiet = F)
      response <-  insistent_risky_get(endpoint_tmp)
      
      ## Parse XML content
      xml_content <- httr::content(response, as = "text")
      xml_file <- xml2::read_xml(xml_content)  
    }
    
    { # Extract metadata ----------------------------------------------------
      
      { ## Setup -------------------------------------------------------------------
        cli_alert('Start XML extract for PMID: {pmid_tmp}')
        i = lst()
        
        node__MedlineCitation = xml2::xml_find_first(xml_file, ".//MedlineCitation")
        node__Article = xml2::xml_find_first(node__MedlineCitation, ".//Article")
        node__PubDate = node__Article %>% xml2::xml_find_first(".//PubDate")
        node__KeywordList  = xml2::xml_find_first(node__MedlineCitation, ".//KeywordList")
        nodes__ArticleIdList = xml2::xml_find_first(xml_file, ".//ArticleIdList") %>%
           xml2::xml_find_all('.//ArticleId')
      }
      
      { ## Extract -----------------------------------------------------------------
        
        ## Simple Extractions
        i$pubMonth = node__PubDate %>% xml2::xml_find_first(".//Month") %>% xml_text_clean()
        i$pubYear = node__PubDate %>% xml2::xml_find_first(".//Year") %>% xml_text_clean()
        i$title = node__Article %>% xml2::xml_find_first(".//Title") %>% xml_text_clean()
        i$abstract = node__Article %>% xml2::xml_find_first(".//AbstractText") %>% xml_text_clean()
        i$keywords = node__MedlineCitation %>%  xml2::xml_find_all('.//Keyword ') %>% xml_text_clean()
        
        ## Identifiers
        nodes__ArticleIdList  %>% 
          walk(function(articleId_tmp){
            type_tmp = articleId_tmp %>%  xml2::xml_attr('IdType')
            i[type_tmp] <<- articleId_tmp %>%  xml2::xml_text()
          })
        
        ## Author list
        nodes__Authors = node__Article %>%  xml2::xml_find_all(".//Author")
        i$authorInfo = nodes__Authors %>% 
          map(function(node_tmp){
            
            node__id_tmp =  node_tmp %>%   xml2::xml_find_all('.//Identifier')
            
            ii = lst(
              LastName = node_tmp %>% 
                xml2::xml_find_first('.//LastName') %>% 
                xml_text_clean(),
              ForeName = node_tmp %>% 
                xml2::xml_find_first('.//ForeName') %>% 
                xml_text_clean(),
              CollectiveName = node_tmp %>%
                xml2::xml_find_first('.//CollectiveName') %>%
                xml_text_clean(),
              ForeInitials = node_tmp %>%
                xml2::xml_find_first('.//Initials') %>%
                xml_text_clean(),
              Affiliation =  node_tmp %>% 
                xml2::xml_find_first('.//Affiliation') %>% 
                xml_text_clean(),
              IdentifierType =  node__id_tmp %>% 
                map_chr(~  xml2::xml_attr(.x, "Source"))%>% 
                pluck(1),
              Identifier =   node__id_tmp %>% 
                xml_text_clean() %>% 
                pluck(1) )
            return(ii)
          })
      }
      
      { ## Add utility flags -------------------------------------------------------

        i$etl$efetch_db = 'pubmed'
        i$etl$pmid = pmid_tmp
        
      }
      
    }
  
  
  { # Return ------------------------------------------------------------------

    
    Sys.sleep(3.5) ## this is for the API rate limit 3 request per 10 seconds. 
    
    cli_alert_success("Metadata harvested for PMID: {pmid_tmp}")
    
    return(i)    
  }
    
  
}

safely_extract_pubmed_efetch_pmid = safely(extract_pubmed_efetch_pmid)
