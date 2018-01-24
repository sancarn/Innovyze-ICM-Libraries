#Find and returns the counts of each flags used in DS_Invert, US_invert and Width fields of the hw_conduit table:
#e.g.
# 100 - S - Surveyed 
# 300 - AS - Assumed
require_relative("libs\\WSDBFlags.rb")

net = WSApplication.current_network
links = net.row_objects("hw_conduit")
puts "Total conduits: #{links.length}"
fields = ["ds_invert","us_invert","conduit_width"]
flags = WSDBFlags.new
fields.each do |field|
    puts ""
    puts "#{field}:"
    (links.group_by {|link| link["#{field}_flag"] })
    .each do |flag,links|
        puts "#{links.length.to_s.ljust(5)} - #{flag.ljust(3)} - #{ flag == "" ? "No flag" : begin flags[flags.index {|f| f.name == flag}].desc rescue "Nil" end}"
    end
end
