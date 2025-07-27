#' gets a SALURBAL file name and operationalizes date (yyyymmdd) of data from file name. It should
#' detect if date is mmddyyyy vs yyyymmdd. For example "BEC_L1AD_20210824.csv" would return `20210824`.
#' 
#' note we also add funcitonality so that if a full path is input we will strip the final file name and use
#' that to derive date.
#' 
#' 
#' @param file_data_tmp: (string) the name of the data file. 
#' 
#' example:
#'  file_data_tmp = "APSL1AD_06132022.csv"
#'  file_data_tmp = "//files.drexel.edu/colleges/SOPH/Shared/UHC/Projects/Wellcome_Trust/Data Methods Core/Dashboards/FAIR Renovations/DTH_L1AD/raw/DTHAR_L1AD_20230123.csv"

get_date_from_data_file_name = function(file_data_tmp){
  
  
  {#  Setup-------------------------------------------------------------------------
    file_tmp = file_data_tmp %>% str_split_1('/') %>% tail(1)
  }
  
  
  raw_date = file_tmp %>%   str_extract("\\d{8}")
  YYYYmmdd = str_sub(raw_date,1,4)%in%paste(2010:2030)
  if (YYYYmmdd){
    # raw date is in YYYYmmdd format ----------------------------------------------
    mmdd_str = str_sub(raw_date, 5,-1L)
    YYY_str = str_sub(raw_date, 1,4)
    YYYYmmdd_str = paste0(mmdd_str,YYY_str)
    return(YYYYmmdd_str)
  } else {
    # raw date is in mmddYYYY format ----------------------------------------------
    
    return(raw_date)
  }
  
}