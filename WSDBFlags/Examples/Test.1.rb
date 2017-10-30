require_relative("libs\\WSDBFlags.rb")

#print all flags
WSDBFlags.new.each do |flag|
    puts [flag.name,flag.desc,flag.defunct,flag.color].join(",")
end

#'S' for Surveyed, 'AS' for Assumed
standard_flags = ["#A", "#D", "#G","#I","#S","#V", "S", "AS"]

#Look for non standard flags:
puts "Non standard flags:"
(WSDBFlags.new.map {|flag| standard_flags.index(flag.name) ? flag : nil}).compact
.each do |flag|
    puts "#{flag.name} - #{flag.desc}"
end
