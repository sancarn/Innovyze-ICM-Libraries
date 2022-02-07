=begin
Simple REST server implementation which implements the following API:  
http://IExchange/auth/pineapples/unrestricted/app/...   #e.g. call to `name` method
http://IExchange/auth/pineapples/unrestricted/db/...   #e.g. call to `name` method
http://IExchange/auth/pineapples/restricted/data       #returns "hello world"

=end
class InfoAssetPublicAPI
  def initialize(masterDatabase)
    @databases = {
      "master" => WSApplication.open("TestServer:30000\\master")
    }
  end
  def data()
    return "hello world"
  end
end


class Authentication
  def auth(token)
    if token == "pineapples"  #clearly not what you'd realistically want to do.
      return {
        "unrestricted" => {
          "app" => WSApplication,
          "db" => WSDatabase
        },
        "api" => InfoAssetPublicAPI.new()
      }
    elsif token = ""
      return {
        "api" => InfoAssetPublicAPI.new(),
        "tms" => ""                      #we will want to implement a TMS implementation here
      }
    end
  end
end


require_relative 'HOOPServer.rb'
server = HOOPServer.new(:Port => 8000)
server.register("root",Authentication.new)
server.start


