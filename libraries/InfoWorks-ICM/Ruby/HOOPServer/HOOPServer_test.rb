require_relative 'HOOPServer.rb'

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
  def exit
    $server.stop
  end
end

begin
  $server = HOOPServer.new({:Port => 8000})
  $server.register("test",Test.new)
  $server.start
rescue Exception=>e
  puts e.message
end