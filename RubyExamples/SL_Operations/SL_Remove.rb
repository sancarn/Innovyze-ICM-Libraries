localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage[:id]
  net = WSApplication.current_network
  to_remove = {}
  net.table_names.each do |table|
    to_remove[table] = []
    net.row_object_collection_selection(table).each do |ro|
      to_remove[table].push(ro.id)
    end
  end
  
  net.clear_selection
  net.load_selection localStorage[:id]
  
  net.table_names.each do |table|
    try_remove = to_remove[table]
    net.row_object_collection_selection(table).each do |ro|
      if try_remove.index ro.id
        ro.selected = false
      end
    end
  end
  
  net.save_selection localStorage[:id]
end
