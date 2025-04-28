require_relative 'WSDatabaseWalker.rb'

OUT_FILE = "H:/Ruby/dbtree.txt"

newWalker = WSDatabaseWalker.new(threaded: false)

File.open(OUT_FILE, "w") do |file|
  newWalker.each do |mo, depth|
    prefix = "|  " * depth + "|-"
    file.puts("#{prefix} [#{mo.type}] #{mo.name}")
  end
end
