#'  Creates a development all request to the specified container
#'  

createDevRequest = function(container_requests, name = '', text = '' ){
  if (text==''){
    con <- textConnection('{"user":null,"id":1666893066674,"email":"ranli2011@gmail.com","title":"local dev test","notes":"dev","boundaries":"on","years":[2002,2018],"countries":["AR","BR","CL","CO","CR","SV","GT","MX","NI","PA","PE"],"attributes":["BECELEVATIONP25","BECPERCAPCO2","CNSLABPART_TOT","CNSLABPART_M","CNSLABPART_F","CNSLABPART_RATIO"]}')
  } else {
    con <- textConnection(text)
  }
  dev_req_name = paste0("dev__local_",name,round(as.numeric(Sys.time())*1000,0),".json")
  storage_upload(container_requests, src=con, dest=dev_req_name)
  list_storage_files(container_requests)
}
