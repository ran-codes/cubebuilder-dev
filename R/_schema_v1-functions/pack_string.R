#' takes in a vector of strings and returns unique packged collapse with ;
#' 
#' example: string_column = 'var_name_raw'; df= base__by_var


pack_string = function(vec_string){
  
  packed_string = vec_string %>% 
    unique() %>% 
    sort() %>% 
    paste(collapse = ";")
  
  return(packed_string)
}

 
pack_string_column = function(df, string_column){
  
 has_column = string_column%in%names(df)
 
 if( has_column){
   non_string_columns = names(df) %>% discard(~.x==string_column)
   
   df_packed = df %>% 
     summarize(!!string_column := pack_string(!!sym(string_column)),
               .by = all_of(non_string_columns)) %>% 
     select(names(df))
 } else {
   df_packed = df
 }
  
  return(df_packed)
}