=begin
  http://IExchange - 

  v2 - 
  GET http://IExchange/databases/InfoNet/Networks/19/hw_nodes
  GET http://IExchange/databases/InfoNet/Networks/19/SQL/10/hw_nodes                //Runs an SQL object and returns selected nodes
  GET http://IExchange/databases/InfoNet/Networks/19/SelectionLists/10/hw_nodes     //Runs a selection list and returns selected nodes


  Can also run this on open networks in the UI:
  GET http://IExchange/current/hw_nodes        //Returns all nodes of current network
  GET http://IExchange/current/hw_pipes        //Returns all pipes of current network


  General setup of REST server:
  class SomeObject
    def value
      return {
        :id => @id
      }
    end
    def initialize(id)
      @id = id
    end
    def some_method
      return {
        :key => "value"
      }
    end
    def nobj
      return SomeObject(@id+1)
    end
    def enum
      return [{"a"=>@id},{"a"=>@id*2},{"a"=>@id*3}].each
    end
    def hash
      return Dictionary.new({
        "1"=>1,
        "a"=>2,
        "2"=>3
      })
    end
    def test
      Test.new()
    end
  end
  class Dictionary
    def initialize(hash)
      @hash
      @hash.each do |key|
        define_method key.to_sym do
          @hash[key]
        end
      end
    end
    def value
      return {}
    end
  end
  class Test
    #If class doesn't define value() method...
    def poop

    end
  end

  RESTServer.register("obj",SomeObject.new(10))

  Registers the following API:
  http://IExchange/obj              // {"id":10}
  http://IExchange/obj/some_method  // {"key":"value"}
  http://IExchange/obj/nobj         // {"id":11}
  http://IExchange/obj/nobj/nobj    // {"id":12}
  http://IExchange/obj/enum         // [{"a": 10},{"a": 20},{"a": 30}].each
  http://IExchange/obj/enum/0/      // {"a": 10}
  http://IExchange/obj/hash         // {}
  http://IExchange/obj/hash/1/      // 1
  http://IExchange/obj/hash/a/      // 2
  http://IExchange/obj/hash/2/      // 3
  http://IExchange/obj/test         // {"class": "Test", "methods": ["poop"]}
=end

class Database
  def initialize(connection_string)
    @conn = connection_string
  end
  def networks(id)
    return 
  end
end

class Network
  def initialize(net)
    @net = net
    net.tables.each do |table|
      define_method table.to_sym do
        Table.new(table,net.row_object_collection(table.name))
      end
    end
  end
  def sql(id)
    
  end
end

class Table
  def initialize(table,roc)
    @table = table
    @roc = roc
  end
  def value
    rows = []
    roc.each do |ro|
      ret = {}
      @table.fields.each do |field|
        if field.data_type == "WSStructure"
          ret[field.name] = []
          ro[field.name].each do |struct_row|
            struct_data = {}
            field.fields.each do |struct_field|
              struct_data[struct_field.name] = struct_row[struct_field.name]
            end
            ret[field.name].push(struct_data)
          end
        else
          ret[field.name] = ro[field.name]
        end
        
      end
      rows.push(ret)
    end
    return rows
  end
end


#if WSApplication.current_network
#  server.register("current",Network.new(WSApplication.current_network))
#else
#  server.register("databases",{
#    "infoWorks"=>{
#      "InfoWorks Master"=> Database.new("server:port/InfoWorks Master"),
#      "InfoWorks Master"=> Database.new("server:port/InfoWorks Master"),
#      "InfoWorks Master"=> Database.new("server:port/InfoWorks Master")
#    },
#    "infoAsset"=>{
#      "InfoAsset Master"=> Database.new("server:port/InfoAsset Master"),
#      "InfoAsset Master"=> Database.new("server:port/InfoAsset Master"),
#      "InfoAsset Master"=> Database.new("server:port/InfoAsset Master")
#    }
#  })
#end

class Authentication
  def auth(token)
    if Digest::SHA256.hexdigest(token) = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
      return {
        "app" => WSApplication,
        "db" => WSDatabase
      }
    end
  end
end


require_relative 'RESTServer.rb'
server = RESTServer.new(:Port => 8000)
server.register("root",Authentication.new)
server.start


