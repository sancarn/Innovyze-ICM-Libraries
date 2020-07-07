class String
  def numeric?
    Float(self) != nil rescue false
  end
end


require 'json'
require 'webrick'
server = WEBrick::HTTPServer.new :Port => 8000
trap 'INT' do
  server.shutdown
end

module BaseElement
  def help
    return {:class => self.class, :id => self.__id__, :methods => self.methods}
  end
end


class Test
  include BaseElement
  def initialize(i=10)
    @i = i
  end
  def value 
    @i
  end
  def test()
    return Test.new(@i+1)
  end
  def print(sMessage)
    return sMessage
  end
  def testHash()
    return {
      "a"=>1,
      "b"=>2,
      3=>3
    }
  end
end


roots = {
  "test" => Test.new
}

def interpratePart(part)
  p part
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

# server.mount_proc "/", Simple
server.mount_proc '/' do |req, res|
  begin
    parts = req.path.split("/")
    parts.shift()
    
    if parts.length == 0
      res.status = 200
      res['Content-Type'] = 'text/json'
      res.body = roots.to_json
      next
    end

    obj = nil
    while (part = parts.shift()) do 
      if obj == nil 
        obj = roots[part]
      else
        if obj.respond_to?(part)
          #Get method and ensure all parameters supplied
          method = obj.method(part.to_sym)
          args = []
          method.parameters.each do |param|
            args.push(interpratePart(parts.shift()))
          end

          #Call method and args
          obj = obj.public_send(part.to_sym, *args)
        elsif obj.respond_to?(:[])
          #Direct support for arrays and hashes

          #Append part back onto front of array
          parts.unshift(part)

          #Get method and ensure all parameters supplied
          method = obj.method(:[])
          args = []
          method.parameters.each do |param|
            args.push(interpratePart(parts.shift()))
          end

          #Call method and args
          obj = obj.public_send(:[], *args)
        else
          raise "Undefined method '#{part}' for #{obj.inspect}"
        end
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
      
      #raise "Undefined behaviour"
    end
  rescue Exception => e
    res.status = 404
    res.body = "#{e.message}\n\n#{e.backtrace.join("\n")}"
  end
end

server.start