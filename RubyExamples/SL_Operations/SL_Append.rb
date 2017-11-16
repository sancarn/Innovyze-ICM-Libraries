require('libs\WSLocalStorage.rb')
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage[:id]
  WSApplication.load_selection localStorage[:id]
  WSApplication.save_selection localStorage[:id]
end
