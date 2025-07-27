generate_relative_path = function(notebook_relative_root, path) {
  file.path(notebook_relative_root,path) %>% stringr::str_remove("^/")
}