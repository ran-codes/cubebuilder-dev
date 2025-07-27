#' takes in a CSV file and retursn a UTF-8 encoded CSV file
#' 
#' 
# 
# csv_path = "datasets/_src/mortality_table.csv"
# csv_path = "datasets/_src/mortality_table_utf8.csv"
# csv_path = "datasets/_src/air_pollution_table.csv"
# original_data = read_csv(csv_path) 


check_utf8_encoding = Vectorize(
  function(csv_path){
    
    file_text <- readLines(csv_path, encoding = "UTF-8")
    
    valid_encoding <- all(utf8::utf8_valid(file_text))
    
    return(valid_encoding)
  },
  vectorize.args = c("csv_path"))

encode_df_as_utf8 = function(original_data){
  copy = original_data
  for (i in seq_along(copy)) {
    if (is.character(copy[[i]])) {
      print(i)
      message(copy[[i]])
      print("--")
      message(iconv(copy[[i]], to = "UTF-8"))
      copy[[i]] <- iconv(copy[[i]], to = "UTF-8")
    }
  }
  return(copy)
}

encode_csv_as_utf8 = function(csv_path){
  
  read_csv(csv_path) %>%
    as.data.table() %>%
    utf8_encoding()
  
    # encode_df_as_utf8() %>% 
    write.csv(
      file = csv_path, 
      row.names = FALSE, 
      fileEncoding = "UTF-8")
  
}
