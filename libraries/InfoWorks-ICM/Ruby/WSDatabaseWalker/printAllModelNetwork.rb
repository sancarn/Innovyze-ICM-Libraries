require_relative 'WSDatabaseWalker.rb'
walker = WSDatabaseWalker.new(threaded: true)
walker.select do |mo, depth|
    mo.type == "Model Network"
end.each do |mo|
    puts mo.path
end