#' this funciton will take in the a lsit of tables, end path and write those to xlsx
#' 
#' 
#' 
#' list_cdbk = base__cdbk_list; path = out_file
#' list_cdbk = src_tables; path = '_shared_storage/0_schema/src.xlsx'; i= NULL


source_parent("identical_cdbk_vs_xslx")

write_salurbal_xlsx = function(list_cdbk, path, local_context){
  
  
  if (!identical_cdbk_vs_xslx(list_cdbk,path, local_context)){
    wb = xlsx::createWorkbook()
    cs_text_bold <- xlsx::CellStyle(wb) +  xlsx::Font(wb, isBold=TRUE)
    map2(names(list_cdbk),list_cdbk, 
         function(table, content){
           sheet =  xlsx::createSheet(wb, sheetName=table)
           xlsx::addDataFrame(as.data.frame(content), 
                        sheet,
                        colnamesStyle = cs_text_bold,
                        row.names = F)    })
    xlsx::saveWorkbook(wb,path)
    cli_alert_success("Wrote {path}")
  }
  
  snapshot_excel(path = path)
}
