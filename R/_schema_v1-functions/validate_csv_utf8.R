#' Takes in a CSV path  that CSV is fully UTF-8 encoded
#'   returns boolean TRUE or FALSE

validate_csv_utf8 = Vectorize(
  function(csv_path){
    
    file_text <- readLines(csv_path, encoding = "UTF-8")
    
    valid_encoding <- all(utf8::utf8_valid(file_text))
    
    return(valid_encoding)
  },
  vectorize.args = c("csv_path"))
