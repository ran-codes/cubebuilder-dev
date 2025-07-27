op_gis_api_endpoints = function(row) {
  ## Setup
  cli_alert("Start API processing {row$format}")
  zipfile_tmp = glue('{path$api_endpoints}/{row$api_file}')
  unzipped_file_tmp = glue('{path$shp}/{row$unzipped_file}')
  if(row$format == 'gdb') unzipped_file_tmp = glue('{path$gdb}/{row$unzipped_file}')
  
  # Copy .gdb/.shp ---------------------------------------------------------------------
  if (row$format %in% c('gdb','shp')) {
    zip(zipfile = zipfile_tmp,
        files = list.files(unzipped_file_tmp, full.names = T),
        flags = "-q",
        extras = '-j')
    cli_alert_success("Op. {row$api_id} to clean")
  } 
  
  # Op. json, parquet ---------------------------------------------------------------------
  if (row$format %in% c('json','parquet')) {
    
    ## Setup
    file_name_tmp = row$api_file %>% str_remove(".zip")
    file_tmp = glue("{path$api_endpoints}/{file_name_tmp}") 
    
    ## Read as sf
    sf_tmp = sf::read_sf(unzipped_file_tmp)
    
    ## Write topojson file
    if (row$format == 'json') sf_tmp %>%
      geojsonio::topojson_write(file = file_tmp)
    if (row$format == 'parquet') sf_tmp %>% 
      geoarrow::write_geoparquet(file_tmp)
    
    ## zip
    zip(zipfile = zipfile_tmp,
        files = file_tmp ,
        flags = "-q",
        extras = '-j')
    file.remove(file_tmp)
    cli_alert_success("Op. {row$api_id} to clean")
  }
  
}
