#' Render Metadata Cell
#'
#' This function processes a single row of metadata, rendering any templated values
#' using a dictionary of key-value pairs.
#'
#' @param row A single row of a data frame containing metadata information.
#'   The row should include columns for dataset_id, geo, iso2, strata_id, year,
#'   column, value, and original_linkage.
#'
#' @return A modified version of the input row with an additional column 'value_rendered'
#'   containing the rendered metadata value.
#'
#' @details
#' The function performs the following steps:
#' 1. Extracts all key strings from the 'value' column that are enclosed in double curly braces.
#' 2. Generates a local dictionary mapping these key strings to composite keys.
#' 3. Attempts to match these composite keys with the global templating dictionary.
#' 4. Renders the value by replacing the key strings with their corresponding values from the dictionary.
#' 5. If a key is not found in the dictionary, it's replaced with a 'MISSING_TEMPLATING_DATA' placeholder.
#'
#' @note This function relies on a global variable 'context$templating_dictionary'
#'   which should be a named list containing the templating key-value pairs.
#'
#' @importFrom stringr str_extract_all str_remove_all str_replace_all
#' @importFrom glue glue
#' @importFrom whisker whisker.render
#'
#' @examples
#' # Assuming context$templating_dictionary is properly set up
# row <- data.frame(
#   dataset_id = "DS1", geo = "L1AD", iso2 = "AR", strata_id = "", year = "2010",
#   column = "source", value = "Data from {{source}} for {{country}}",
#   original_linkage = I(list(c("dataset_id", "iso2")))
# )
# rendered_row <- render_metadata_cell(row, context)
# rendered_row <- render_metadata_cell_optimized(row, context)
#'
#' @export

render_metadata_cell = function(row, context){ 
  # row = to_render %>%  slice(6)
  ## Get list of keys to process
  key_strings = row$value %>% 
    str_extract_all('\\{\\{[a-zA-Z0-9-]+\\}\\}') %>% 
    unlist() %>% 
    str_remove_all('\\{\\{|\\}\\}') %>% 
    unique()

  if (length(key_strings) > 0){
    
    ## Generate local key to composite key dictionary
    key_list = unlist(row$original_linkage)
    dataset_id = ifelse('dataset_id' %in% key_list, row$dataset_id, '')
    geo = ifelse('geo' %in% key_list, row$geo, '')
    iso2 = ifelse('iso2' %in% key_list, row$iso2, '')
    strata_id = ifelse('strata_id' %in% key_list, row$strata_id, '')
    year = ifelse('year' %in% key_list, row$year, '')
    column = row$column
    dictionary_local = key_strings %>%
      map(~glue("{.x}__{dataset_id}__{geo}__{iso2}__{strata_id}__{year}__{column}")) %>%
      set_names(key_strings)
    
    ## Render each key
    dictionary_clean = dictionary_local %>% 
      imap(~{
        # .x = dictionary_local[[2]]; .y = names(dictionary_local)[2]
        
        ## Flexible render value
        key_raw = .y
        composite_key_tmp = .x
        if (composite_key_tmp %in% names(context$templating_dictionary) ) {
          ## Case 1: direct match
          composite_key_available_tmp = composite_key_tmp
        } else {
          
          composite_key_tmp_without_geo = composite_key_tmp %>%
            str_remove_all('L1AD|L1UX|L1MA|L1XS|L2_5|L3') %>%
            str_remove_all('L2')
          if (composite_key_tmp_without_geo %in% names(context$templating_dictionary)) {
            ## Case 2: match after removing GEO
            composite_key_available_tmp = composite_key_tmp_without_geo
          } else {
            composite_key_tmp_without_geo_iso2 = composite_key_tmp %>%
              str_remove_all('L1AD|L1UX|L1MA|L1XS|L2_5|L3') %>%
              str_remove_all('L2') %>%
              str_replace_all('_AR_|_BR_|_CL_|_CO_|_CR_|_GT_|_MX_|_NI_|_PA_|_PE_|_SV_',"__")  
            if (composite_key_tmp_without_geo_iso2 %in% names(context$templating_dictionary)) {
              ## Case 3: match after removing GEO and ISO2
              composite_key_available_tmp = composite_key_tmp_without_geo_iso2
            } else {
              
              
              composite_key_tmp_minimal = paste0(key_raw,"____________", str_replace(composite_key_tmp, ".*__", ""))
              if (composite_key_tmp_minimal %in% names(context$templating_dictionary)) {
                composite_key_available_tmp = composite_key_tmp_minimal
              } else {
                composite_key_available_tmp = NA
              }
            }
          }
        }
        
    
        ## Return
        render_value = ifelse(is.na(composite_key_available_tmp), 
                              glue("{{{{{composite_key_tmp}-MISSING_TEMPLATING_DATA}}}"), 
                              context$templating_dictionary[[composite_key_available_tmp]])

        dictionary_inner = list(render_value) %>% set_names(key_raw)
        dictionary_inner
      }) %>% 
      map(~{.x %>% pluck(1) })
    
    rendered_composite_value <<- whisker.render(row$value, dictionary_clean) %>% 
      str_replace_all("(?<=\\S);(?=\\S)", "; ")
 
    
    row %>% 
      mutate(value_rendered = rendered_composite_value) %>% 
      return()  
  } else {
    row %>% 
      mutate(value_rendered = value) %>% 
      return( )
  }
}


render_metadata_cell_optimized <- function(row, context) {
  # Extract key strings once
  key_strings <- unique(unlist(str_extract_all(row$value, '\\{\\{([a-zA-Z-]+)\\}\\}')))
  key_strings <- sub("\\{\\{(.*)\\}\\}", "\\1", key_strings)
  
  if (length(key_strings) > 0) {
    # Generate local key to composite key dictionary

    key_list <- unlist(row$original_linkage)
    values <- c(row$dataset_id, row$geo, row$iso2, row$strata_id, row$year)
    names(values) <- c("dataset_id", "geo", "iso2", "strata_id", "year")
    values <- values[names(values) %in% key_list]
    values["column"] <- row$column
    
    # Create composite keys
    dictionary_local <- paste(key_strings, 
                              paste(values, collapse = "__"), 
                              sep = "__")
    names(dictionary_local) <- key_strings
    
 

    # Render each key
    dictionary_clean <- sapply(dictionary_local, function(composite_key) {
      composite_key_variants <- c(
        composite_key,
        gsub("L1AD|L1UX|L1MA|L1XS|L2_5|L3|L2", "", composite_key),
        gsub("_AR_|_BR_|_CL_|_CO_|_CR_|_GT_|_MX_|_NI_|_PA_|_PE_|_SV_", "__", 
             gsub("L1AD|L1UX|L1MA|L1XS|L2_5|L3|L2", "", composite_key))
      )
      
      for (variant in composite_key_variants) {
        if (variant %in% names(context$templating_dictionary)) {
          return(context$templating_dictionary[[variant]])
        }
      }
      
      return(paste0("{{", sub(".*__", "", composite_key), "-MISSING_TEMPLATING_DATA}}"))
    })
    
    # Render the value
    rendered_value <- whisker::whisker.render(row$value, dictionary_clean)
    rendered_value <- gsub("(?<=\\S);(?=\\S)", "; ", rendered_value, perl = TRUE)
    
    row$value_rendered <- rendered_value

  } else {
    row$value_rendered <- row$value
  }
  
  return(row)
}
