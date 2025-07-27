makeNotionURL = function(type=NULL, database = NULL, page_id = NULL){
  case_when(
    type == 'page' ~ paste0("https://api.notion.com/v1/pages/", page_id),
    type == 'database' ~ paste0('https://api.notion.com/v1/databases/', database, '/query'),
    type == 'new page' ~ 'https://api.notion.com/v1/pages',
    TRUE ~ 'ERROR'
  ) %>% 
    return()
}

flattenDatabaseContentIntoDataFrame <- function(results){
  
  # adding error-catching when the results are none (i.e., a filter w no results)
  if(length(results) < 1 ){
    dd <- data.frame("results" = "none")
    warning("There are no results from the query. Check your filters. A data.frame will still be exported, with col_name = results and row1 = none")
    
  }else{
    # the results (i.e., rows) are extracted into a simple data.frame with value being a list of each item's properties and id's
    items <- tibble::enframe(results)
    
    # now, for each item, we will extract a tidy data.frame where we have all of the columns
    dd <- NULL
    for(i in 1:nrow(items)){
      ## before we tidy up,
      ## add NA's if there is no cover or icon AND we want to based on the option in the parameters of the function
      
  
      
      # this is a tidy dataset with column 1 = name (i.e., value.object.type, etc) and col2 = value (i.e,. d3f0ee76-fc3b-426c-8d23-cff84800b0d6)
      tmp <- tibble::enframe(unlist(items[[i, 2]]))
      
      # to avoid duplicates, (such as two relationships tied to a page) I will condense them into 1 separated by a pipe
      tmp <- tmp %>%
        group_by(name) %>%
        summarise("value" = paste(value, collapse = " | "))
      
      # now, I want to keep this as 1 row in a big data set, so I will pivot_wider
      tmp <- tidyr::pivot_wider(tmp)
      
      # now, I will create one big dataset, I will use dplyr in case columns are not exactly the same, which could be the case if one or various of the properties are missing
      dd <- dplyr::bind_rows(dd, tmp)
    }
  }
  
  return(dd)
}


read_notion_database <- function(database, token, filters = NULL){
  options(dplyr.summarise.inform = FALSE) # to supress all the grouping warnings!
  
  # Get all pages in database
  new_cursor <- TRUE; dd <- NULL; cursor <- NULL # Setup page looping
  while( new_cursor ){
    
    # Setup request
    headers = c(`Authorization` = token, `Notion-Version` = '2022-02-22', `Content-Type` = 'application/json' )
    url = makeNotionURL('database', database)
    body =list("filter" = filters, "start_cursor" = cursor)
    
    # Request
    r <-  httr::POST(url = url,
                     httr::add_headers(.headers = headers),
                     body = body,
                     encode = "json") %>% 
      httr::content()
    
    # Reduce to dataframe
    tmp <- flattenDatabaseContentIntoDataFrame( r$results )
    dd <- dplyr::bind_rows(dd, tmp)
    
    # Setup request
    new_cursor <- r$has_more
    cursor <- r$next_cursor
  }
  
  return(dd)
}