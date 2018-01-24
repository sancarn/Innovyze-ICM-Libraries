require_relative('libs\WSLocalStorage.rb')
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage[:id]
  net = WSApplication.current_network
  net.clear_selection
  net.save_selection localStorage[:id]
end
