=begin
The following implementation implements an ICM Exchange HTTP API.
    * Includes documentation
    * API is mostly read-only
    * Can be run on an IExchange server or in the UI
      * IExchange: http://IExchange:{port}/api/v1/master
      * IExchange: http://IExchange:{port}/api/v1/open/server:40000\InfoAsset%20Master/...
      * UI:        http://localhost:{port}/api/v1/current_network

    * Can be used to extract table data, and data of the entire network
    * Can terminate via terminate/test (by default)
      * http://localhost:{port}/api/terminate/test
=end

$terminate_pass = "test"
$master_database = "test"
$master_network_type = "Collection Network"
$master_network_id = 20
$port = 8000
$entry = "api"

MESSAGE_ADDRESS = true

#require_relative 'HOOPServer.rb'
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
    next h
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
  return rows
end

#entry-point http://iexchange/api
class HTTP_API
  annotate!
  
  _docs(description: "Version 1 of the api", params: [])
  def v1
    Application.new
  end

  _docs(description: "Retrieve the value of the object", params: [])
  def value 
    return {
      "self" => self.inspect,
      "metadata" => {
        "computer" => ENV["COMPUTERNAME"]
      },
      "docs" => {
        "description" => "A stateless HTTP OOP API end point",
        "methods" => getMethodDocs(self)
      }
    }
  end
  
  _docs(description: "", params: [])
  def terminate(s)
    if s==$terminate_pass
      $server.stop
    end
  end
end

#entry-point http://iexchange/api/v1
class Application
  annotate!

  #@example-url http://IExchange/api/v1/current_network
  _docs(description: "Access the current network in UI mode", params: [])
  def current_network()
    return Network.new(WSApplication.current_network)
  end

  #@example-url http://IExchange/api/v1/open/testServer:40000\Test
  _docs(description: "Open a database with the specified connection string", params: [
    {name: "connection_string", type: "string", description: "Connection string of database. See https://github.com/sancarn/Innovyze-ICM-Libraries/tree/master/docs/Infoworks-ICM#open-exchange-only"}
  ])
  def open(connection_string)
    Database.new(connection_string)
  end

  #@example-url http://IExchange/api/v1/master
  _docs(description: "Retrieve the assigned master database.", params: [])
  def master
    Database.new($master_database)
  end

  #@example-url http://IExchange/api/v1
  _docs(description: "Retrieve the value of the object", params: [])
  def value()
    {
      "self" => self.inspect,
      "metadata" => {},
      "docs" => {
        "methods" => getMethodDocs(self)
      }
    }
  end
end

#entry-point http://iexchange/api/v1/{database}
#entry-point http://iexchange/api/v1/master
#entry-point http://iexchange/api/v1/open/{connection-string}
class Database
  annotate!

  def initialize(connection_string)
    @conn = connection_string
    @@cache ||= {}
    @@cache[:db] ||= {}
    @db = @@cache[:db][@conn] || (@@cache[:db][@conn] = WSApplication.open(@conn))
  end

  #@example-url http://IExchange/api/v1/master/collection_network/10
  _docs(description: "Get the collection network with the specified ID", params: [
    {name: "id", type: "int", description: "ID of the collection network to retrieve"}
  ])
  def collection_network(id)
    return Network.new(@db.model_object_from_type_and_id("Collection Network", id))
  end
  
  #@example-url http://IExchange/api/v1/master/model_network/10
  _docs(description: "Get the model network with the specified ID", params: [
    {name: "id", type: "int", description: "ID of the collection network to retrieve"}
  ])
  def model_network(id)
    return Network.new(@db.model_object_from_type_and_id("Model Network", id))
  end

  #@example-url http://IExchange/api/v1/master/master
  _docs(description: "Get the master network for this database", params: [])
  def master
    return Network.new(@db.model_object_from_type_and_id($master_network_type,$master_network_id))
  end

  #@example-url http://IExchange/api/v1/master/model_object_from_type_and_id/Model%20Network/10
  _docs(description: "Obtain a model object from the database based on type and id", params: [
    {name: "type", type: "string", description: "The type of the model object to retrieve"},
    {name: "id", type: "int", description: "ID of the model object to retrieve"}
  ])
  def model_object_from_type_and_id(type,id)
    return ModelObject.new(@db.model_object_from_type_and_id(type,id))
  end

  #TODO: Dump entire database structure as JSON
  #@example-url http://IExchange/api/v1/master/tree/123e4567-e89b-12d3-a456-426614174000
  _docs(description: "Obtain the entire database structure as JSON. After obtaining an existing payload, poll on this function to obtain the data.", params: [
		{name: "uuid", type: "string", description: "The UUID of the tree object to retrieve"},
  ])
  def tree(uuid)
    @@cache[:tree] ||= {}
		begin
			@@cache[:tree][uuid][:status] ||= @@cache[:tree][uuid][:threads].all? {|t| !t.status}
			return {
				type: "Tree Response",
				status: @@cache[:tree][uuid][:status],
				tree: @@cache[:tree][uuid][:data],
				error: nil
			}
		rescue Exception => e
			return {
				type: "Tree Response",
				status: false,
				tree: nil,
				error: "No tree with the UUID \"#{uuid}\" exists." 
			}
		end
  end
  
	#@example-url http://IExchange/api/v1/master/tree/123e4567-e89b-12d3-a456-426614174000
	_docs(description: "Obtain the entire database structure. This function is used to request a new payload. Use tree/{{uuid}} to obtain existing payloads.", params: [])
  def getTree()
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
      }
  end

  #@example-url http://IExchange/api/v1/master
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
    }
  end
end

#TODO: Currently unknown what kind of interface we'd want here. Perhaps tree() to export whole JSON representation of database?
class ModelObject
  annotate!

  def initialize(mo)
    @mo = mo
  end

  #@example-url http://IExchange/api/v1/master/model_object_from_type_and_id/Model%20Network/10
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
    }
  end
end

#entry-point http://iexchange/api/v1/{database}/{network}
#entry-point http://iexchange/api/v1/master/master
#entry-point http://iexchange/api/v1/master/model_network/{id}
#entry-point http://iexchange/api/v1/master/collection_network/{id}
#entry-point http://iexchange/api/v1/open/{connection-string}/master
#entry-point http://iexchange/api/v1/open/{connection-string}/model_network/{id}
#entry-point http://iexchange/api/v1/open/{connection-string}/collection_network/{id}
#entry-point http://iexchange/api/v1/current_network
class Network
  annotate!

  def initialize(net)
    @net = closer_net = net.is_a?(WSNumbatNetworkObject) ? net.open : net
    if net.is_a?(WSNumbatNetworkObject)
      ObjectSpace.define_finalizer(self, proc {closer_net.close})
    end
  end

  #@example-url http://IExchange/api/v1/master/master/tables
  _docs(description: "Obtain a table of the network", params: [
    {name: "table_name", type: "string", description: "The name of the table to retrieve"}
  ])
  def tables(table_name)
    return Table.new(@net,table_name)
  end

  #@example-url http://IExchange/api/v1/master/master/scenarios/KST/...
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
    end
  end

  #@example-url http://IExchange/api/v1/master/master
  _docs(description: "Obtain information about the object", params: [])
  def value()
    {
      #"self" => self.inspect,
      "metadata" => {
        "model_object" => {
          "name" => @net.model_object.name,
          "path" => @net.model_object.path
        },
        "state" => {
          "scenario" => @net.current_scenario
        },
        "tables"=>@net.tables.map {|t| t.name},
        "scenarios" => @net.enum_for(:scenarios).to_a
      },
      "docs" => {
        "methods" => getMethodDocs(self)
      }
    }
  end
end

#entry-point http://iexchange/api/v1/{database}/{network}/tables/{table-name}
#entry-point http://iexchange/api/v1/master/master/tables/{table-name}
class Table
  annotate!

  def initialize(net, table)
    @net = net
    @table = table
  end

  #@example-url http://IExchange/api/v1/master/master/tables/_links/data
  _docs(description: "Obtain all data of the object in JSON representation", params: [])
  def data
    return rocData(@net.row_object_collection(@table))
  end

  #@example-url http://IExchange/api/v1/master/master/tables/_links/data_where/link_type='cond'
  _docs(description: "Obtain all data of the object in JSON representation where a SQL condition is met", params: [])
  def data_where(sQuery)
    @net.clear_selection
    @net.run_SQL(@table,sQuery)
    return rocData(@net.row_object_collection_selection(@table))
  end

  #@example-url http://IExchange/api/v1/master/master/tables/_links
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
    }
  end
end

if MESSAGE_ADDRESS
  WSApplication.message_box("Connect at http://#{ENV["COMPUTERNAME"]}:#{$port}/#{$entry}", "OK", "information", false)
end

begin
  $server = HOOPServer.new({:Port => $port})
  $server.register($entry,HTTP_API.new)
  $server.start
rescue Exception=>e
  puts e.message
end
