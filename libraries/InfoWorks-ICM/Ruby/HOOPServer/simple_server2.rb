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

require_relative 'HOOPServer.rb'
require_relative 'Annotations.rb'
require 'securerandom'

#_docs(description: "", params: [])
def getMethodDocs(instance)
  klass = instance.class
  (klass.instance_methods - Object.methods).select do |m|
    next klass.annotations(m)[:docs]
  end.map do |m|
    h = {}
    h[:name] = m
    klass.annotations(m)[:docs].each do |k,v|
      h[k] = v
    end
  end
end

def rocData(roc)
  rows = []
  roc.each do |ro|
    ret = {}
    ro.table_info.fields.each do |field|
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
  return rows.to_json
end

$master_database = "test"
$master_network_type = "Collection Network"
$master_network_id = 20

class HTTP_API
  _docs(description: "Version 1 of the api", params: [])
  def v1
    Application.new
  end

  _docs(description: "Retrieve the value of the object", params: [])
  def value 
    return {
      "self" => self.inspect,
      "metadata" => {},
      "docs" => {
        "description" => "A stateless HTTP OOP API end point"
        "methods" => getMethodDocs(self)
      }
    }.to_json
  end
end

class Application
  annotate!

  #@example-url http://IExchange/application/current_network
  _docs(description: "Access the current network in UI mode", params: [])
  def current_network()
    return Network.new(WSApplication.current_network)
  end

  #@example-url http://IExchange/application/open/testServer:40000\Test
  _docs(description: "Access the current network in UI mode", params: [
    {name: "connection_string", type: "string", description: "Connection string of database. See https://github.com/sancarn/Innovyze-ICM-Libraries/tree/master/docs/Infoworks-ICM#open-exchange-only"}
  ])
  def open(connection_string)
    Database.new(connection_string)
  end

  #@example-url http://IExchange/application/master
  _docs(description: "Retrieve the assigned master database.", params: [])
  def master
    Database.new($master_database)
  end

  #@example-url http://IExchange/application
  _docs(description: "Retrieve the value of the object", params: [])
  def value()
    {
      "self" => self.inspect,
      "metadata" => {},
      "docs" => {
        "methods" => getMethodDocs(self)
      }
    }.to_json
  end
end

class Database
  annotate!

  def initialize(connection_string)
    @conn = connection_string
    @@cache ||= {}
    @@cache[:db] ||= {}
    @db = @@cache[:db][@conn] || (@@cache[:db][@conn] = WSApplication.open(@conn))
  end

  #@example-url http://IExchange/application/master/collection_network/10
  _docs(description: "Get the collection network with the specified ID", params: [
    {name: "id", type: "int", description: "ID of the collection network to retrieve"}
  ])
  def collection_network(id)
    return Network.new(@db.model_object_from_type_and_id("Collection Network", id))
  end
  
  #@example-url http://IExchange/application/master/model_network/10
  _docs(description: "Get the model network with the specified ID", params: [
    {name: "id", type: "int", description: "ID of the collection network to retrieve"}
  ])
  def model_network(id)
    return Network.new(@db.model_object_from_type_and_id("Model Network", id))
  end

  #@example-url http://IExchange/application/master/master
  _docs(description: "Get the master network for this database", params: [])
  def master
    return Network.new(@db.model_object_from_type_and_id($master_network_type,$master_network_id))
  end

  #@example-url http://IExchange/application/master/model_object_from_type_and_id/Model%20Network/10
  _docs(description: "Obtain a model object from the database based on type and id", params: [
    {name: "type", type: "string", description: "The type of the model object to retrieve"},
    {name: "id", type: "int", description: "ID of the model object to retrieve"}
  ])
  def model_object_from_type_and_id(type,id)
    return ModelObject.new(@db.model_object_from_type_and_id(type,id))
  end

  #TODO: Dump entire database structure as JSON
  #@example-url http://IExchange/application/master/tree
  _docs(description: "Obtain the entire database structure as JSON", params: [])
  def tree(uuid=nil)
    if uuid 
      @@cache[:tree][uuid][:status] ||= @@cache[:tree][uuid][:threads].all? {|t| !t.status}
      return {
        type: "Tree Response",
        status: @@cache[:tree][uuid][:status],
        tree: @@cache[:tree][uuid][:data]
      }.to_json
    else
      @@cache ||= {}
      @@cache[:tree] ||= {}
      @@cache[:tree][uuid = SecureRandom.uuid()] = {}
      @@cache[:tree][uuid][:threads] = []
      @@cache[:tree][uuid][:data]  = []
      @@cache[:tree][uuid][:status] = false

      def walk(uuid,moc)
        moc.each do |mo|
          @@cache[:tree][uuid][:data].push({parent: mo.parent_id, id: mo.id, type: mo.type, name: mo.name, path: mo.path})
          @@cache[:tree][uuid][:threads].push(
            Thread.new(uuid) do |uuid|
              walk(uuid,mo.children)
            end
          )
        end
      end
      
      #Start search
      root_objects = WSApplication.current_database.root_model_objects
      walk(root_objects)
      return {
        type: "Tree Reference",
        treeID: uuid
      }.to_json
    end
  end

  #@example-url http://IExchange/application/master
  _docs(description: "Obtain information about the object", params: [])
  def value()
    {
      "self" => self.inspect,
      "metadata" => {
        "root_objects": @db.root_model_objects.enum_for(:each).map do |mo|
          next {parent: mo.parent_id, id: mo.id, type: mo.type, name: mo.name, path: mo.path}
        end
      },
      "docs" => {
        "methods" => getMethodDocs(self)
      }
    }.to_json
  end
end

#TODO: Currently unknown what kind of interface we'd want here. Perhaps tree() to export whole JSON representation of database?
class ModelObject
  annotate!

  def initialize(mo)
    @mo = mo
  end

  #@example-url http://IExchange/application/master/model_object_from_type_and_id/Model%20Network/10
  _docs(description: "Obtain information about the object", params: [])
  def value()
    {
      "self" => self.inspect,
      "metadata" => {
        id: @mo.id,
        name: @mo.name,
        type: @mo.type,
        path: @mo.path,
        parent: @mo.parent_id
      },
      "docs" => {
        "methods"=> getMethodDocs(self)
      }
    }.to_json
  end
end

class Network
  annotate!

  def initialize(net)
    @net = closer_net = net.is_a?(WSNumbatNetworkObject) ? net.open : net
    if net.is_a?(WSNumbatNetworkObject)
      ObjectSpace.define_finalizer(self, proc {closer_net.close})
    end
  end

  #@example-url http://IExchange/application/master/master/tables
  _docs(description: "Obtain a table of the network", params: [
    {name: "table_name", type: "string", description: "The name of the table to retrieve"}
  ])
  def tables(table_name)
    return Table.new(@net,table_name)
  end

  #@example-url http://IExchange/application/master/master/scenarios/KST/...
  _docs(description: "Obtain a scenario of the network", params: [
    {name: "scenario_name", type: "string", description: "The name of the scenario to retrieve"}
  ])
  def scenarios(scenario_name)
    @net.current_scenario = scenario_name
    return self
  end

  #TODO: All tables
  _docs(description: "Obtain all data of the object in JSON representation", params: [])
  def data
    return @net.tables.enum_for(:each).map do |table|
      next {
        table: table.name,
        data: rocData(@net.row_object_collection(table.name))
      }
    end.to_json
  end

  #@example-url http://IExchange/application/master/master
  _docs(description: "Obtain information about the object", params: [])
  def value()
    {
      "self" => self.inspect,
      "metadata" => {
        "tables"=>tables.map {|t| t.name},
        "scenarios" => @net.scenarios
      },
      "docs" => {
        "methods" => getMethodDocs(self)
      }
    }.to_json
  end
end

class Table
  annotate!

  def initialize(net, table)
    @net = net
    @table = table
  end

  #@example-url http://IExchange/application/master/master/tables/_links/data
  _docs(description: "Obtain all data of the object in JSON representation", params: [])
  def data
    return rocData(@net.row_object_collection(@table)).to_json
  end

  #@example-url http://IExchange/application/master/master/tables/_links/data_where/link_type='cond'
  _docs(description: "Obtain all data of the object in JSON representation where a SQL condition is met", params: [])
  def data_where(sQuery)
    @net.clear_selection
    @net.run_SQL(@table,sQuery)
    return rocData(@net.row_object_collection_selection(@table)).to_json
  end

  #@example-url http://IExchange/application/master/master/tables/_links
  _docs(description: "Obtain information about the object", params: [])
  def value()
    {
      "self" => self.inspect,
      "metadata" => {
        "fields"=>@net.table(@table).fields.map do |f| 
            next {
              "name" => f.name,
              "type" => f.data_type,
              "description" => f.description
            }
        end
      },
      "docs" => {
        "methods" => getMethodDocs(self)
      }
    }.to_json
  end
end




HOOPServer.register("api",HTTP_API.new)

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