class Monk end

class Sandbox end

box=Sandbox.new
box.instance_eval('
def amazing
   "stuff"
end

p amazing + " stuff"

def shit
   42
end

p amazing + shit.to_s')


begin
    p amazing
rescue
    p "We couldn't evaluate 'amazing' from outside!"
end

p box.instance_eval('amazing')


box=Sandbox.new

begin
  p box.instance_eval('amazing')
rescue
  p "We couldn't evaluate 'amazing' from inside a new object!"
end
