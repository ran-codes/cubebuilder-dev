#' Gives a preview of a reactable for notebooks
#' 


salurbal_reactable <- function(data_tmp){
  
  constrain_width <- function(value) {
    if (is.na(value)) {
      return(NA_character_)
    }
    
    if (is.integer(value)) {
      # For numeric values, format to 2 decimal places
      formatted_value <- value
    } else if (is.numeric(value)) {
      # For numeric values, format to 2 decimal places
      formatted_value <- sprintf("%.2f", value)
    } else {
      # For non-numeric values, convert to character and truncate if necessary
      formatted_value <- as.character(value)
      if (nchar(formatted_value) > 40) {
        formatted_value <- paste0(substr(formatted_value, 1, 37), "...")
      }
    }
    formatted_value
  }
  
  
  reactable(
    data_tmp,
    defaultColDef = colDef(
      cell = constrain_width,
      minWidth = 150,
      style = list(overflow = "hidden", textOverflow = "ellipsis")
    ),
    searchable = TRUE,
    filterable = TRUE,
    sortable = TRUE,
    resizable = TRUE,
    # height = 600,
    compact = T,
    pagination = TRUE,
    defaultPageSize = 15,
    showPageSizeOptions = TRUE,
    pageSizeOptions = c(10, 15, 20, 25, 50, 100),
    theme = reactableTheme(
      borderColor = "#dfe2e5",
      stripedColor = "#f6f8fa",
      highlightColor = "#f0f5f9",
      cellPadding = "8px 12px"
    )
  )
}


salurbal_renovation_reactable <- function(data, reorder = T) {
  
  { # Setup -------------------------------------------------------------------
    
    ## Reorder columns for acesibilty
    columns_to_end = c(
      'observation_type','strata_id','var_name_raw','geo',
      'dataset_instance','dataset_id', 'dataset_version', 'schema_version','day', 'month')
    columns_to_front <- c('var_name','var_def','var_label','public','domain','subdomain')
    data_tmp = data %>% 
      head(n = 100)
    if (reorder) {
      data_tmp <- data_tmp %>%
        select(
          # First, select columns_to_front that exist in the dataframe
          intersect(columns_to_front, names(.)),
          # Then, select all other columns except those in columns_to_end
          !any_of(c(columns_to_front, columns_to_end)),
          # Finally, select the columns_to_end that exist in the dataframe
          intersect(columns_to_end, names(.))
        )
    }
    
    
  }
  
  
  
  
  
  # Create the reactable
  salurbal_reactable(data_tmp)
}
