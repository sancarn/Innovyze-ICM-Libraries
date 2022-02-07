class String
  def numeric?
    Float(self) != nil rescue false
  end
end
class NullStream
  def <<(o); self; end
end


module BaseElement
  def help
    return {:class => self.class, :id => self.__id__, :methods => self.methods}
  end
end

require 'json'
require 'webrick'
#HTTP OOP Server
class HOOPServer
  #Constructor
  def initialize(options)
    @roots = {}
    @options = options

    #fixes some bugs...]
    @options[:Logger] ||= WEBrick::Log.new(NullStream.new)

    #Start server
    @server = WEBrick::HTTPServer.new(options) #{:Port => 8000}
    trap 'INT' do
      @server.shutdown
    end

    #Main server loop:
    @server.mount_proc '/' do |req, res|
      handle(req,res)
    end
  end

  #Register name to object
  def register(sName, object)
    #Ensure object extends base element (for help method)...
    object.extend(BaseElement)

    #Bind object to root on name
    @roots[sName] = object
  end

  #Start server
  def start
    @server.start
  end

  #Exit the server
  def stop
    @server.shutdown
  end
  
  private
  def handle(req,res)
    begin
      parts = req.path.split("/")
      parts.shift()
      
      if parts.length == 0
        res.status = 200
        res['Content-Type'] = 'text/json'
        res.body = @roots.to_json
        return
      end
  
      obj = nil
      while (part = parts.shift()) do 
        if obj == nil 
          obj = @roots[part]
        else
          if obj.respond_to?(part)
            method = obj.method(part.to_sym)
          elsif obj.respond_to?(:[])
            #Get method
            method = obj.method(:[])
            
            #Didn't use part as method name so append part back onto stack
            parts.unshift(part)
          else
            raise "Undefined method '#{part}' for #{obj.inspect}"
          end

          #noOptional forces methods the method to only consume non-optional arguments
          #E.G. doSomething/noOptional/1/2  vs  doSomething/1/2/true/false/3
          #for signiature:   def doSomething(a,b,c=true,d=false,e=3)

          if parts[0] == "noOptional"
            parts.shift()
            optional = false
          else
            optional = true
          end

          
          #Get number of required params
          paramCount = optional ? method.parameters.length : method.parameters.select {|e| e[0]==:req}.length

          #Check enough arguments are given:
          if paramCount > parts.length
            raise ArgumentError, "wrong number of arguments (given #{parts.length}, expected #{method.parameters.length}) for method '#{method.name.to_s}' of object #{obj.inspect}"
          end
          
          #Obtain arguments from expected args
          args = []
          paramCount.times do
            args.push(interpratePart(parts.shift()))
          end

          #Call method and args
          obj = obj.public_send(method.name, *args)
        end
      end
      
      if obj.respond_to?(:value)
        res.status = 200
        res['Content-Type'] = 'text/json'
        res.body = obj.value.to_s
      else
        res.status=200
        res['Content-Type'] = 'text/json'
        res.body = obj.to_json
      end
    rescue Exception => e
      res.status = 404
      res.body = "404 #{e.message}\n\n#{e.backtrace.join("\n")}"
    end
  end

  def interpratePart(part)
    if part.numeric?
      if part.to_i == part.to_f
        return part.to_i
      else
        return part.to_f
      end
    else
      return part
    end 
  end
end
