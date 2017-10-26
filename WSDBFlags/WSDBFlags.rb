require 'win32ole'
class IWDBHelper
	attr_accessor :iwdb, :type, :mdb
	def initialize(iwdb)
		@iwdb = iwdb
	end
	
	def type
		if @type
			return @type
		end
		
		#Get useful variables
		path = @iwdb.path
		ext = File.extname(path)
		#Do some checks on data collected
		if ext == ".icmt"
			@type = "Transportable"
		elsif ext == ".icmm"
			@type = "Standalone"
		elsif /(?<hostname>.+):(?<port>\d+)\/(?<dbname>.+)/.match(path)	
			@type = "Workgroup"
		else
			@type = "Unknown"
		end
		
		#Return database type.
		return @type
	end
	
	def mdb
		if @mdb
			return @mdb
		end
		
		if self.type == "Workgroup"
			#pe-le-file3:40000/523-110_Newthorpe_ICM6.5
			#==>
			#File.open("\\\\pe-le-file3\\icm-workgroups/523-110_Newthorpe_ICM6.5.sndb/master.wdb")
			
			Dir.glob('\\pe-le-file3\icm-workgroups/523-110_Newthorpe_ICM6.5.sndb/*')
			path = /(?<hostname>.+):(?<port>\d+)\/(?<dbname>.+)/.match(@iwdb.path)			
			@mdb = "\\\\#{path[:hostname]}\\icm-workgroups/#{path[:dbname]}.sndb/master.wdb"
		elsif self.type == "Standalone"
			#Instantiate match
			icmm = ""
			
			#Find match
			File.open(@iwdb.path).each_line do |line|
				icmm = /^GUID,1,(?<guid>.+?)\s*$/.match(line)
				if icmm
					break;
				end
			end
			
			@mdb = "#{@iwdb.path}\\..\\#{icmm[:guid]}\\"
		elsif self.type == "Transportable"
			@mdb = @iwdb.path
		else
			@mdb = nil
		end
		
		return @mdb
	end
end

#	Dir.glob "\\\\pe-le-file3\\icm-workgroups/523-110_Newthorpe_ICM6.5.sndb/*"
#	>["\\\\pe-le-file3\\icm-workgroups/523-110_Newthorpe_ICM6.5.sndb/blobs", "\\\\pe-le-file3\\icm-workgroups/523-110_Newthorpe_ICM6.5.sndb/master.wdb", "\\\\pe-le-file3\\icm-workgroups/523-110_Newthorpe_ICM6.5.sndb/s169-1333.log", "\\\\pe-le-file3\\icm-workgroups/523-110_Newthorpe_ICM6.5.sndb/s169-1333.wdb", "\\\\pe



class WSFlag
	attr_reader :name, :desc, :color, :defunct
	def initialize(name,desc,color,defunct)
		@name = name
		@desc = desc
		@color = color
		@defunct = defunct
	end
end

class WSDBFlags < Array
	def initialize()
		_iwdb = IWDBHelper.new(WSApplication.current_database)
		
		if _iwdb.type == "Workgroup"
			regex = /flags.+id, description, defunct, color(?<data>(?:.|\s)*?)[\x00-\x08]/
			
			#"C:\\Users\\jwa\\Desktop\\TBD\\master.db"  #DEBUG PATH
			match = File.binread(_iwdb.mdb).force_encoding('BINARY').scan(
				/flags.+id, description, defunct, color(?<data>(?:.|\s)*?)[\x00-\x08]/m
			)
			
			if match
				@raw = match[0][0]
			end
		elsif _iwdb.type == "Standalone"
			#Instantiate data
			data = ""
			
			#Get data
			File.open(_iwdb.mdb + "RootPrefs.DAT").each_line do |line|
				data =/^flags\s*,\s*1\s*,\s*(?<flags>".+")\s*$/m.match(line)
				if data
					break;
				end
			end
			
			@raw = eval(data[:flags].gsub(/""/,"\\\""))
		else
			return 0
		end
		
		@raw.each_line do |line|
			if line.strip() != ""
				
				flag = /\s*(?<name>.+)\s*,\s*(?<desc>.+)\s*,\s*(?<defunct>\d)\s*,\s*(?<color>\d+)/.match(line.strip()) 
				
				if flag
					self.push(WSFlag.new(flag[:name],eval(flag[:desc]),flag[:color], flag[:defunct]))
				end
			end
		end
	end
	
	def keys
		self.map {|flag| flag.name }
	end
	
	def values
		self.keys
	end
	
	def descriptions
		self.map {|flag| flag.desc }
	end
	
	def colors
		self.map {|flag| flag.color }
	end
	
	def defunctFlags
		self.map {|flag| flag.defunct }
	end
	
end

#Remove helper library: - requires more thought.
#Object.send(:remove_const, :IWDBHelper)

#~~~~~~~~
#EXAMPLE:
#~~~~~~~~
dbflags = WSDBFlags.new
dbflags.each do |flag|
	puts flag.name + "," + flag.desc  + "," + flag.color
end

puts dbflags.keys.to_s
puts dbflags.descriptions.to_s
