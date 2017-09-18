 # Using Gems in ICM
 
 Apparrently you should be able to require other Gem paths like so:
 
 ```
 Gem.use_paths(Gem.dir, ["#{RAILS_ROOT}/vendor/gems"])
 Gem.refresh # picks up path changes
 ```

# Pre-requesites

 Step 1: gem install gem_name --install-dir /some/directory/you/can/write/to
 
 Step 2: Make sure you have a `.gemrc` file in your home directory that looks something like this:

```
gemhome: /some/directory/you/can/write/to
gempath:
 - /some/directory/you/can/write/to
 - /usr/local/lib/ruby/gems/1.8
```


`gemhome` is where gems should look first when seeking a gem. `gempath` is all the paths it should check in when seeking a gem. So in the `.gemrc` above, I'm telling my code to look first in the local directory, and if not found, check the system gem directory.

Step 3: Be aware that some code - even code within gems - can make assumptions about where gems are located. Some code may programmatically alter `gempath` or `gemhome`. You may need to "alter it back" in your own code.

Unfortunately there isn't a lot of / any documentation on how to do this, so it will only ever be experimental.

# Native Gem capabilities

If you have admin rights you may be able to write files to `Gem.dir` directly. However I have not tested this so far.
