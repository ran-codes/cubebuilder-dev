#' validate_reviewed_metadata_cube - enforces all final metadata cube standards but allows for partitioning of metadata relative to final_data_cube
#'  - the complete referential consistency is only enforced in production level testing

validate_final_metadata_cube  <- function(final_metadata_cube, local_context) {
  

  validated_final_metadata_cube = final_metadata_cube %>%
    # Structural Integrity Tests
    verify(has_columns(.,
                       list(local_context$vec__admin_final_metata_cube_required_columns),
                       message = "all final metadata cube required columns"
                       )) %>%
    verify(does_not_have_columns(.,
                                 list(local_context$vec__admin_data_columns_all),
                                 message = "no final metadata cube excluded columns"
                                 )) %>%
    verify(valid_column_names(., local_context, cube_type = 'metadata'))  %>%
    ## Referential Integrity Tests
    verify(composite_key_integrity(., local_context, cube_type = 'metadata')) %>%
    verify(composite_key_uniqueness(., local_context)) %>%
    verify(left_structural_integrity(., local_context$final_data_cube, local_context)) %>%
    verify(left_referential_integrity(., local_context$final_data_cube, local_context)) %>%
    ## Content Integrity Tests
    verify(has_all_character_column_types(.)) %>%
    verify(valid_ci_compilation(., local_context)) %>% #
    assert(non_missing_value, domain, subdomain, var_def, public)  %>%
    assert(in_set(local_context$df_domains$domain), domain) %>%
    assert(
      function(subdomain) {
        split_domains <- str_split(subdomain, ";") %>% 
          unlist() %>% 
          trimws()
        all(split_domains %in% local_context$df_subdomains$subdomain)
      }, 
      subdomain, 
      description = "all subdomains must be valid") |> 
    # select(-subdomain_unnested) |> 
    assert(in_set(c('0','1','2','3','9')), public) %>%
    verify(valid_no_trailing_seperator(., local_context)) %>% 
    verify(valid_no_templating_syntax(., local_context))
  
  ## Other aserrtions
    
  
  detect_compiled_partition = nrow(final_metadata_cube) == nrow(local_context$metadata_cube_key_template)
  
  if (any(local_context$is_not_partitioned, detect_compiled_partition)) {
    cli_alert_info("Start Functional Metadata to Data referential integrity tests")
    validated_final_metadata_cube = validated_final_metadata_cube %>% 
      verify(functional_referential_integrity(., local_context$final_data_cube, local_context))
  } else {
    cli_alert_info("Partitioned metadata cube detected, skipping data-metadata referential integrity tests")
  }
  
  return(validated_final_metadata_cube)
  
}

