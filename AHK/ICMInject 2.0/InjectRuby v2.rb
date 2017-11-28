require 'win32ole'

class Sandbox
  def Sandbox.new()
	return binding
  end
end

invoker = WIN32OLE.connect("{5c172d3c-c8bf-47b0-80a4-a455420a6911}")
code = invoker.scripts[$$]
mode = invoker.modes[$$]

invoker.rbActive($$)
  case mode 
    when 0
      Sandbox.new.eval(code,__FILE__,__LINE__)
    when 1
      eval(code,binding,__FILE__,__LINE__)
    else
      box = "box" + mode.to_s
      $boxes ||= {}
      $boxes[box] ||= Sandbox.new
      $boxes[box].eval(code,__FILE__,__LINE__)
  end
invoker.rbClosing($$)