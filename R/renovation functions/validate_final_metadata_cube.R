#' validate_reviewed_metadata_cube - enforces all final metadata cube standards but allows for partitioning of metadata relative to final_data_cube
#'  - the complete referential consistency is only enforced in production level testing

validate_final_metadata_cube  <- function(final_metadata_cube, context) {
  

  validated_final_metadata_cube = final_metadata_cube %>%
    # Structural Integrity Tests
    verify(has_columns(.,
                       list(context$vec__admin_final_metata_cube_required_columns),
                       message = "all final metadata cube required columns"
                       )) %>%
    verify(does_not_have_columns(.,
                                 list(context$vec__admin_data_columns_all),
                                 message = "no final metadata cube excluded columns"
                                 )) %>%
    verify(valid_column_names(., context, cube_type = 'metadata'))  %>%
    ## Referential Integrity Tests
    verify(composite_key_integrity(., context, cube_type = 'metadata')) %>%
    verify(composite_key_uniqueness(., context)) %>%
    verify(left_structural_integrity(., context$final_data_cube, context)) %>%
    verify(left_referential_integrity(., context$final_data_cube, context)) %>%
    ## Content Integrity Tests
    verify(has_all_character_column_types(.)) %>%
    verify(valid_ci_compilation(., context)) %>% #
    assert(non_missing_value, domain, subdomain, var_def, public)  %>%
    assert(in_set(context$df_domains$domain), domain) %>%
    assert(
      function(subdomain) {
        split_domains <- str_split(subdomain, ";") %>% 
          unlist() %>% 
          trimws()
        all(split_domains %in% context$df_subdomains$subdomain)
      }, 
      subdomain, 
      description = "all subdomains must be valid") |> 
    # select(-subdomain_unnested) |> 
    assert(in_set(c('0','1','2','3','9')), public) %>%
    verify(valid_no_trailing_seperator(., context)) %>% 
    verify(valid_no_templating_syntax(., context))
  
  ## Other aserrtions
    
  
  detect_compiled_partition = nrow(final_metadata_cube) == nrow(context$metadata_cube_key_template)
  
  if (any(context$is_not_partitioned, detect_compiled_partition)) {
    cli_alert_info("Start Functional Metadata to Data referential integrity tests")
    validated_final_metadata_cube = validated_final_metadata_cube %>% 
      verify(functional_referential_integrity(., context$final_data_cube, context))
  } else {
    cli_alert_info("Partitioned metadata cube detected, skipping data-metadata referential integrity tests")
  }
  
  return(validated_final_metadata_cube)
  
}

