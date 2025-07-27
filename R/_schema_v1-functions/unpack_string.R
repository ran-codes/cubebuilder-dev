#' Unpacks string seperated by ;
#' 
#' 
#' ## potential problems: need to think about when there is text other than things that 
#' that need unpacking. e.g. "{{population}}. The underlying shape files were from OSM.".
#' 

unpack_string = function(string){
  
  items = string %>% 
    str_split(";") %>% 
    unlist() %>% 
    str_trim()
  
  list = list(items)
  
  return(list)
}

