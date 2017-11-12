Ruby tip - Run ruby commands when ICM is closed

In the last article I briefly explained that when running ruby scripts in ICM they all run in the same process.

> The first thing to note about the ruby runtime in ICM, is that ICM always appears to use the same virtual machine to run all ruby scripts in one process.

It was explained that you could use global variables to store data in-process, and later use that same data in other running scripts. The interesting thing here is that exploits such as these, using the single process nature of the RubyVM, extend to many other base features of ruby giving us more power when building out ICMExchange ruby scripts.

In this article we will talk about the `at_exit` method of the Kernel object.

`Kernel.at_exit(&block)` will run some ruby code when the ruby code terminates. See the following example for usage details:

```ruby
Kernel.at_exit do 
	WSApplication.message_box("Please don't kill me! :(","A dying process", nil)
end
```

When exactly will the ruby code run? Well given that all ruby code is ran in the same RubyVM, the same RubyVM must continue running after your script terminates. For this reason, at_exit will not be called when your ruby script terminates... It's instead called when ICM terminates! When ICM terminates so does the ruby VM, and thus your commands will also be called!

Admitedly when I first tried this, I was quite confused... 'Why wasn't `at_exit` called when my ruby scripts were terminated?'. However now that I know about the other behaviour it makes a lot more sense. This is very nice as it brings a lot more power and control to the UI ruby script environment.

For example, with this you can easily make temporary selection lists. Imagine doing an audit on your network which creates hundreds of selection lists. In most cases you wouldn't want them cluttering up your database. In these cases you can do the following:

```ruby    #### verification on method names needs to be done

mogID = WSApplication.Input_Box("What's your model group ID?","","",nil).to_i
mog = WSApplication.current_database.find_by_type_and_id("Model group",mogID)
sl = mog.new_model_object("Selection list")
mo.save_selection(sl)

Kernel.at_exit do 
	mo.delete(sl)
end
```

Basically, any time you want something to be temporary and only for that instance of ICM, you can use the `at_exit` method. Then everything will be removed after ICM is quit by the user. Fantastic!
