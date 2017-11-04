# ICMExchange (Ruby) - Cross script data sharing

When writing software it is often useful to keep track of changes made by the user. For this you need to be able to store data until it's required in the future. When making ruby applications in ICM, the same is true but ICM provides no way to access data between scripts. Or does it?

To investigate further we need to look explore how the ruby runtime in ICM works, or at least, how I believe it works.

The first thing to note about the ruby runtime in ICM, is that ICM always appears to use the same virtual machine to run all ruby scripts in one process. You can see it as the following example:

```ruby
class Sandbox
end

Sandbox.new.instance_eval(rubyCode)
```

As shown, each time the code is evaluated in it's own new instance of a ruby object.  This is important because it means that ruby scripts can't intentionally interact with eachother. I.E. The local variables of one ruby script are not accessible from another. To see this in action you can run the following 2 ruby scripts:

Script1.rb

```ruby
a = 1
puts a #=> 1
```

Script2.rb

```ruby
puts a #=> Error
```

The thing to notice however is that in the Sandbox example we are doing nothing to stop users writing to class variables or global variables:

Script1.rb

```ruby
$a = 1
@@b = 2
puts $a  #=> 1
puts @@b #=> 2
```

Script2.rb

```ruby
puts $a  #=> 1
puts @@b #=> 2
```

ICM's Ruby virtual machine works in a very similar way to this and I wouldn't be surprised if it was identical. The important thing to note though is this allows us to share data between scripts run in the same instance of ICM, in-process without the need for a helper file.

So what can we use this for?

Well a good example which I've used before is the ability to append to selection lists. You can run 1 script to select a selection list to append to, and another script to append the current selection to that selection list!

Select selection list:

```ruby
a=WSApplication.input_box("Enter selection list ID:", "", nil)
$selection_list_id = a
```

Append to selection list:

```ruby
if $selection_list_id != nil
	WSApplication.load_selection $selection_list_id		#Add the old selection list to the current selection
	WSApplication.save_selection $selection_list_id		#Save the selection
end
```

However, imagine if you have hundreds of addons installed, with all these random floating variables. You would never be sure that your addon will work because a variable you used might be used by another addon, so your scripts may clash. So I built a little class which can help you sandbox your scripts:

```ruby
class WSLocalStorage < Hash
	def initialize(identifier)
		$local ||= {}
		$local[identifier] ||= {}
		self = $local[identifier]
	end
end
```

You can use the system as follows:

Store data with first ruby script:

```ruby
#Initialise with your own GUID. Generate one online here: https://www.guidgen.com/
myStorage = WSLocalStorage.new("02c45c3d-e512-41c6-91c6-76638ab6e4dc")

#Assign propertiess to storage object
myStorage.greeting  = "Hello"
myStorage.name      = "Frank"
myStorage.someArray = [1,2,"abc"]
```

Use data with second ruby script:

```ruby
#Initialise with your own GUID. Generate one online here: https://www.guidgen.com/
myStorage = WSLocalStorage.new("02c45c3d-e512-41c6-91c6-76638ab6e4dc")

puts myStorage.greeting.to_s + " " + myStorage.name.to_s
myStorage.someArray.each do |e|
	puts e.to_s
end
```

So to remake the previous selection list example, the final code would be:

**SelectionList_Select.rb**

```ruby
#'Selection List' operations GUID: a8344089-9f06-4058-9955-57283c090659
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
localStorage.id = WSApplication.input_box("Enter selection list ID:", "", nil)
```

**SelectionList_Append.rb**

```ruby
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage.id != nil
	WSApplication.load_selection localStorage.id		#Add the old selection list to the current selection
	WSApplication.save_selection localStorage.id		#Save the selection
end
```

Remember to create a new GUID for each new application/bundle you make! The GUID is what ensures that your data will only be shared by your own application scripts.
