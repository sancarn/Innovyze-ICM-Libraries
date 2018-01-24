
require 'win32ole'
ahk=WIN32OLE.connect("{6B39CAA1-A320-4CB0-8DB4-352AA81E460E}")

#Demonstrate data extraction and manipulation from ruby:
puts ahk.name
ahk.name = "Bill"
puts ahk.name

#Demonstrate AHK method calling from ruby
ahk.Message("Hello, world!")

#Demonstrate callback from AHK to ruby
class Callback
	attr_accessor :running
	
	def initialize()
		@running = 1
	end
	
	def complete(o)
		puts "Completed OLE Task.\nResponse: " + o.to_s
		@running = 0
	end
end

#create a callback object to pass to AHK.
cb = Callback.new

#Execute AHK function and pass callback object ot AHK
ahk.BeginWork(cb)

#Wait until response from AHK object
sleep(0.001) until cb.running==0

#Quit ahk process
ahk.Quit()