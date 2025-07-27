#' takes in a dataframe with year column and other columns. Will return a dataframe with the same
#' columns but the year column is packed into a readable format. 
#' 
#' df = merged_tidy
# years_string = '2012, 2013, 2014, 2015, 2016'
# years_string =  '2012, 2013, 2014, 2015, 2016, 2019'
# years_string =  '2012; 2012; 2013; 2013; 2014; 2014; 2015; 2015; 2016; 2016'
# years_string = "2014-2016"
# years_string = 2000:2009
# years_string = c("2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017","2018", "2019", "2020", "2000", "2001", "2002", "2003", "2004", "2005","2006", "2007", "2008", "1997", "1998", "1999")
# years_string = c("2012-2016", "2010-2014")
# years_string <- c("2011", "2017", "2012", "2010", "2012-2013","2012-2014", "2013", "2013-2014", "2014", "2015")

pack_year_string = function(years_string){
  
  pack_int_vector = function(years){
    
    years = years %>% 
      unlist() %>% 
      as.integer() %>%  
      unique() %>% 
      sort()
    # Create a new vector that contains the difference between consecutive years
    differences <- diff(years)
    
    # Check if all differences are equal to 1 (i.e. the years are sequential)
    ranges <- split(years, cumsum(c(1, diff(years) != 1)))
    ranges <- lapply(ranges, range <- function(x) {
      if (length(x) > 1) paste0(min(x), "-", max(x)) else as.character(x)
    })
    range <- paste0(paste(unlist(ranges), collapse = "; "))
    
    return(range)
  }
  
  is__vector = length(years_string) > 1
  has__seperator = str_detect(years_string,";|,") %>% any()
  is__all_int  = all(!years_string %>% str_detect('-'))
  is__all_ranges = all(years_string %>% str_detect('-'))
  is__some_ranges = any(years_string %>% str_detect('-')) & !is__all_ranges
  # print(years_string)
  

  if (!is__vector){
    if (!has__seperator) return(years_string)
    if (has__seperator) return(str_split(years_string, ';') %>% pack_int_vector())
  }
  if (is__vector){
    if(!has__seperator){
      if (is__all_int) years = return(years_string %>% pack_int_vector())
      if (is__all_ranges) return(years_string %>% paste(collapse = ';'))
      if (is__some_ranges) {
        res__ranges = years_string %>% keep(~str_detect(.x,'-')) %>% sort()  %>% paste(collapse = ';') 
        res__ints = years_string %>% discard(~str_detect(.x,'-')) %>% pack_int_vector()
        return( paste(c(res__ranges,res__ints),collapse = ';'))
      }
    }
  
    if ( has__seperator){
      cli_abort("NEED TO CODE THIS CONDITION")
    }
  }
  


  
}

pack_year = function(df){
  
  
  if (!'year'%in%names(df)) return(df)
  original_column_order = names(df)
  
  non_year_columns = names(df) %>% discard(~.x=='year')
  
  df_year_packed = df %>% 
    summarize(year = pack_year_string(year),
              .by = all_of(non_year_columns)) %>% 
    select(any_of(original_column_order))
  
  return(df_year_packed)
}