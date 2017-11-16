# 'Selection List' operations GUID: a8344089-9f06-4058-9955-57283c090659
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")

# Get the user to select the selection list ID they wish to operate on:
localStorage[:id] = WSApplication.input_box("Enter selection list ID:", "Select selection list", "").to_i

# Check that model object is of type selection list, and error if not:
iwdb = WSApplication.current_database
if !iwdb.model_object_from_type_and_id("Selection list",localStorage[:id])
  localStorage[:id] = nil
  WSApplication.message_box("ID selected is not the ID of a selection list.","!","OK",nil)
end
