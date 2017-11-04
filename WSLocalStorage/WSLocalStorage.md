# ICMExchange (Ruby) - Cross script data sharing

TODO:

* Talk about all 4 variable scopes

It is often useful to allow the user to put your application in a certain state which can then be acted upon at a later time. For this you need to be able to store data until it's required in the future. When making ruby applications in ICM, the same is true but ICM provides no way to access data between scripts. Or does it?

To investigate further we need to explore how the ruby runtime in ICM works, or at least an accurate representation of it.

The first thing to note about the ruby runtime in ICM, is that ICM always appears to use the same virtual machine to run all ruby scripts in one process. You can see it in the following example:

```ruby
class Sandbox
end

Sandbox.new.instance_eval(YOUR_RUBY_CODE)
```

As shown, each time the code is evaluated, it is done so in it's own new instance of a ruby Sandbox object using instance_eval.  This is important because it means that ruby scripts can't intentionally interact with eachother. I.E. The local variables of one ruby script are not accessible from the local variables from another. To see this in action run the following ruby script in [a ruby REPL](https://repl.it/languages/ruby):

```ruby
class Sandbox
end

Sandbox.new.instance_eval("
  local = 'abc'
")

puts "---"

puts Sandbox.new.instance_eval("local")

puts "---"
```

You should see the following will be outputted:

```
---
undefined local variable or method `local' for #<Sandbox:0x0055c5dbccbab8>
(repl):10:in `instance_eval'
(repl):10:in `instance_eval'
(repl):10:in `<main>'
```

As shown, the variable "local" is not accessible in the second instance of the Sandbox object, even though a variable with the same name was set earlier in an old Sandbox object. The thing to notice however is that in the Sandbox example we are doing nothing to stop users writing to `Class` variables or `Global` variables:

```ruby
class Sandbox
end

Sandbox.new.instance_eval("
  $global = 'abc'
  @@class = 'def'
")

puts "---"

puts Sandbox.new.instance_eval("$global")
puts Sandbox.new.instance_eval("@@class")

puts "---"
```

The above code should return:

```
 ---
 abc
 def
 ---
=> nil
```

ICM's RubyVM works in exactly the same way to this, and I wouldn't be surprised if the implementation was identical. The important thing to note is that this allows us to share data between scripts ran in the **same instance** of ICM, **in-process without the need for any external files**.

To make this local storage easier to manage, I've made a class, `WSLocalStorage`, which gives access to the power of this storage without polluting the global namespace.

## So what?

So what's the use of this behaviour? Let's look at an example.

Say you want to make a ruby application which helps users build selection lists from the ground up. Traditionally in ICM there is no way to 'build up' a selection list. You can make a selection, and then make a selection list from your selection, but if you want to overwrite your existing selection list, add to it, or remove objects from it there is no easy way to do this built into ICM. Instead let's build a set of scripts which helps users build up, overwrite, delete from and clear their selection lists.

The different script files we'll make are the following:

```
SL_Select.rb
SL_Append.rb
SL_Remove.rb
SL_Clear.rb
SL_Overwrite.rb
```

`SL_Select.rb` will be used to allow the user to select the selection list to operate on. The easiest way to do this is by getting the user to provide the selection list's ID. `SL_Select.rb` will then store this data in a `WSLocalStorage` object. From here it can easily be accessed for `SL_Append`, `SL_Remove`, `SL_Clear` and `SL_Overwrite` operations.

**SL_Select.rb**

```ruby
#'Selection List' operations GUID: a8344089-9f06-4058-9955-57283c090659
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")

#Get the user to select the selection list ID they wish to operate on:
localStorage["id"] = WSApplication.input_box("Enter selection list ID:", "Select selection list", "").to_i

#Check that model object is of type selection list, and error if not:
iwdb = WSApplication.current_database
if !iwdb.model_object_from_type_and_id("Selection list",localStorage["id"])
  localStorage["id"] = 0
  WSApplication.message_box("ID selected is not the ID of a selection list.","!","OK",nil)
end
```

Here we create a new object with our application identifier as a name. I created the application identifier by going to [guidgen.com](https://www.guidgen.com/) and copying the GUID/UUID generated. The reason programmers use GUIDs is because the probability of them not being unique is tiny.

> While each generated GUID is not guaranteed to be unique, the total number of unique keys (2^128 or 3.4×10^38) is so large that the probability of the same number being generated twice is very small. For example, consider the observable universe, which contains about 5×10^22 stars; every star could then have 6.8×10^15 universally unique GUIDs.

For this reason we are creating an identifier which is almost certainly unique and is not going to clash with any other applications anyone else has made. Then we set the `id` key of our `WSLocalStorage` object to the ID of a selection list given by the user. Afterwards we check whether the ID provided is indeed a selection list. If not then we'll notify the user and set the `id` key of our `WSLocalStorage` object to `0`, which'll be useful for stoppign future errors. Next, let's work on the operations.

**SL_Append.rb**

```ruby
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage["id"] && localStorage["id"] != 0
  WSApplication.load_selection localStorage["id"]
  WSApplication.save_selection localStorage["id"]
end
```

Here we use our application identifier to grab the current localStorage object currently setup by `SL_Select`. Then we make sure the `id` stored in the `WSLocalStorage` object is non `0` and non `nil`. Then we use this ID to load the selection list. When using `load_seletion` ICM actually appends the selection list to the current selection (as if you were holding control while draggin the selection list). Ultimately ICM has already done the job of appending the selection lists for us, now we just need to save the changes, which we do with `save_selection`.

**SL_Remove.rb**

```ruby
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage["id"] && localStorage["id"] != 0
  net = WSApplication.current_network
  to_remove = {}
  net.table_names.each do |table|
    to_remove[table] = []
    net.row_object_collection_selection(table).each do |ro|
      to_remove[table].push(ro.id)
    end
  end
  
  net.clear_selection
  net.load_selection localStorage["id"]
  
  net.table_names.each do |table|
    try_remove = to_remove[table]
    net.row_object_collection_selection(table).each do |ro|
      if try_remove.index ro.id
        ro.selected = false
      end
    end
  end
  
  net.save_selection localStorage["id"]
end
```

`SL_Remove` is slightly more complicated. To summarise, we firstly store the current selection in an object, which afterwards we can use as a lookup to find those objects with IDs which shouldn't be selected. From this, after loading the selection list, we can easily deselect those parts which shouldn't be selected. At the end of the operation we save the selection list, saving our changes.

**SL_Clear.rb**

```ruby
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage["id"] && localStorage["id"] != 0
  net = WSApplication.current_network
  net.clear_selection
  net.save_selection localStorage["id"]
end
```

Going back to the easier operations, to clear the selection list, we simply save a blank selection list to the current chosen selection list.

**SL_Overwrite.rb**

```ruby
localStorage = WSLocalStorage.new("a8344089-9f06-4058-9955-57283c090659")
if localStorage["id"] && localStorage["id"] != 0
  WSApplication.current_network.save_selection localStorage["id"]
end
```

And to finish it off, to overwrite a selection list, we simply save the current selection list to the current chosen selection list. With the above ruby scripts we can have much more flexibility over our selection lists in InfoWorks ICM and InfoNet.

Hopefully this shows you the power of `WSLocalStorage` object. It really allows users to interact with your ruby scripts, in the application they were designed in. Because currently in ICM the amount a user can really intergrate with ICM is very limited.
