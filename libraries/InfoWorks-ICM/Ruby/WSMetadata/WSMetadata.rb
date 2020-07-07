=begin #---------------------------------------------------------------------------------

WSMetadata provides a way of storing additional information alongside ICM objects in a model.


=end   #---------------------------------------------------------------------------------

require 'date'

class MetadataBase
  # Public class variables
  @name = nil
  @description = nil
  @classes = []
  @include=false
  class << self
    attr_reader :name
    attr_reader :description
    attr_reader :classes
    attr_reader :include
  end
  
  #Public variable state
  attr_accessor :state

  

  def initialize(metadata,table_name, object_id)
    @table_name = table_name
    @object_id  = object_id
    @metadata = metadata

    # Instance variables
    @state = {}
    @table_name = ""
    @object_id = ""
  end

  def prompt()
    data = [[self.class.name + " INFORMATION","READONLY",""]]
    @state.each do |key,value|
      p value.class
      case value.class.name
      when "Fixnum", "Float"
        data << [key, "NUMBER" , value, 3]
      when "String"
        data << [key, "STRING" , value]
      when "DateTime"
        data << [key, "DATE"   , value]
      when "TrueClass", "FalseClass"
        data << [key, "BOOLEAN", value]
      else
        puts "oh no"
      end
    end

    return data
  end

  def setState(data)
    @state.each do |key,value|
      @state[key] = data[key]
    end
    return true
  end

  def save()
    @metadata["model"][@table_name][@object_id][self.name] = @state
  end
end

class MetadataObjectTitle < MetadataBase
  @name = "Title"
  @description = "To store title information"
  @classes = []
  @include = false 

  def prompt()
    return [@table_name,"READONLY",@object_id]
  end
end

class MetadataNew < MetadataBase
  @name = "NEW"
  @description = "Used add new structured metadata to object."
  @classes = ["hw_pipe"]
  @include = false #Include in options

  def prompt()
    classes = Module.constants.select {|e| e.to_s[/Metadata.+/]}
    @classes = classes.map {|cls| Module.const_get(cls)}.select {|cls| cls.include}
    @classNames = @classes.map {|cls| cls.name}
    return [
      ["ADD NEW","READONLY",""],
      ["Select Type","STRING", "", nil, "LIST", @classNames]
    ]
  end
  def setState(data)
    if data["Select Type"]
      @newRequired = true
      classReq = classes.select {|cls| cls.name == data["Select Type"]}

      if classReq.length > 0
        @metadata["model"][@table_name][@object_id][data["Select Type"]] = classReq[0].new(@metadata,@table_name, @object_id).state
      end
    end
    return false
  end
end

class MetadataBlockage < MetadataBase
  @name = "Blockage"
  @description = "Used to store information on a pipe about blockages"
  @classes = ["hw_pipe"]
  @include = true #Include in options
  def initialize(metadata,table_name, object_id)
    super

    @state = {
      "Original Pipe Height (mm)" => "",
      "Survey Type"               => "",
      "Survey Date"               => DateTime.now.to_s,
      "Blockage Type"             => "",
      "Restriction %"             => 100.0
    }
  end
  def prompt()
    return [
      ["BLOCKAGE INFORMATION","READONLY",""],
      ["Original Pipe Height (mm)","NUMBER",@state["Original Pipe Width"]],
      ["Survey Type","STRING",@state["Survey Type"],nil,"LIST",["CCTV","MANHOLE SURVEY","OTHER (use notes)"]],
      ["Survey Date","DATE",DateTime.parse(@state["Survey Date"])],
      ["Blockage Type","STRING",@state["Blockage Type"],nil,"LIST",["RUBBLE","SILT","FAT","RAGGING","COLLAPSE","OTHER (use notes)"]],
      ["Restriction %","NUMBER",@state["Restriction %"], 3]
    ]
  end
  def setState(data)
    super
    @state["Survey Date"] = @state["Survey Date"].to_s
    return true
  end

  

  # ...
end

class MetadataCSO < MetadataBase
  @name = "CSO"
  @description = "Used to store information about a CSO"
  @classes = ["hw_weir","hw_conduit","hw_orifice","hw_usercontrol","hw_pump"]
  @include = true #Include in options

  def initialize(metadata,table_name, object_id)
    super
    @state = {
      "Pipe is CSO Spill"        => false,
      "Pipe is CSO Continuation" => false,
      "Pipe is CSO Incoming"     => false,
      "SMP UID" => 0
    }
  end
end

class MetadataSPS < MetadataBase
  @name = "SPS"
  @description = "Used to store information about a SPS"
  @classes = ["hw_weir","hw_conduit","hw_orifice","hw_usercontrol","hw_pump"]
  @include = true #Include in options

  def initialize(metadata,table_name, object_id)
    super
    @state = {
      "Pipe is SPS Rising Main" => false,
      "Pipe is SPS Incoming"     => false,
      "SMP UID" => 0
    }
  end
end

class MetadataWWtW < MetadataBase
  @name = "WWtW"
  @description = "Used to store information about a WWtW"
  @classes = ["hw_weir","hw_conduit","hw_orifice","hw_usercontrol","hw_pump"]
  @include = true #Include in options
  
  def initialize(metadata,table_name, object_id)
    super
    @state = {
      "Pipe is WWtW Inlet" => false,
      "SMP UID" => 0
    }
  end
end



=begin
WSMetadata example:
{
  "model":{
    "hw_conduit":{
      "SK12345678":{
        "Blockage": {
          "Original Pipe Height (mm)" : 500,
          "Survey Type" : "CCTV",
          "Survey Date" : "2001-01-01T00:00:00+00:00",
          "Blockage Type" : "Fat",
          "Restriction %" : 50
        },
        "WWtW": {
          "Pipe is WWtW Inlet": true,
          "SMP UID": 13
        }
      }
    }
  }
}
=end
class WSMetadata
  @metadata = {}
  @classes = []

  def initialize(file)
    if !file
      raise "No file specified."
    end

    require 'json'
    @metadata = JSON.parse(File.new(file))
    @classes = Module.constants.select {|e| e.to_s[/Metadata.+/]}.map {|cls| Module.const_get(cls)}.select {|cls| cls.include}
  end
  def openPrompt(objects)
    # If objects not initialised, init on selection
    if !objects
      objects = self._querySelection()
    end

    structures = []
    objects.each do |obj|
      #Add title element
      structures.push(MetadataObjectTitle.new(@metadata,obj[:table_name],obj[:object_id]))
      
      savedMetadata = @metadata["model"][obj[:table_name]][obj[:object_id]]
      savedMetadata.each do |key,value|
        classes = @classes.select {|cls| cls.name == key}
        if classes.length > 0
          cls = classes[0]
          structures.push(cls.new(@metadata,obj[:table_name],obj[:object_id]))
        end
      end

      #Add new element
      structures.push(MetadataNew.new(@metadata,obj[:table_name],obj[:object_id]))
    end

    promptData = []
    structures.each do |struct|
      promptData += struct.prompt
    end

    results = WSApplication.prompt("Metadata Viewer", prompt, false)
    
    # Segment results based on structures
    resultSets = structures.map {}

    # Call set states
    continue? = true
    resultSets.each do |state|
      if !state[:structure].setState(state)
        continue? = false
      end
    end

    if !continue?
      openPrompt(newObjects?)
    end

    # Identify where/if saveReady() false


    # Call save

  end
  def WSMetadata._prompt()

  end
  def WSMetadata._querySelection()
    #Selection will be an array of hashes as follows: [{:type=>"hw_manhole", :obj=> "SK12345678"},{...},...]
  
    #Initialise selection
    selection=[]
    
    # Collect all selected objects
    net.tables.each do |table|
      net.row_object_collection_selection(table.name).each do |obj|
        selection.push({:type=>table.name, :obj=> obj.id})
      end
    end
    
    return selection
  end
end


# return Hash[net.tables.map {|table| [table.name,net.row_object_collection_selection(table.name).to_enum.map{|e| e.id}]}.select {|e| e[1].length>0}]