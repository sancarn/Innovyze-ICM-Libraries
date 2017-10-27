# class `WSDBFlags`

## Introduction to flags

Data Flags are a powerful tool for recording the source and integrity of data in the model. Some types of InfoWorks ICM version controlled items, e networks, support data flags for many of their data fields.

InfoWorks ICM includes several standard built in data flags but additional custom flags can be added. For example, data can be flagged for the data source, or the data accuracy.

At our organisation we have numerous standard flags set out for us by the water companies we work for.

For this reason, when we try to identify model health, it is often important to check which flags were used in the model and where in the model these flags were used. ICMExchange does provide some good ways to do this, e.g. 

```ruby
net = WSApplication.current_network
net.row_objects("hw_conduit").each do |link|
    puts link.conduit_width_flag
end
```
	
However ICM does not provide an easy way for us programmers to find out what these flags mean.

Recently when I was making a model audit algorithm in Ruby, we wanted to identify which flags in the model were non-standard and flag them up in our audit log. We also wanted to be able to generate a flag table where the counts of each flag where listed next to their specific flags and descriptions. E.G.

Link: US_Invert

| Flag | Description | Count |
|------|-------------|-------|
| #A   | Asset Data  |  800  |
| SY   | Surveyed    |  100  |
| AS   | Assumed     |  100  |

----

## In comes `WSDBFlags`

So what can be done if Innovyze doesn't provide the interface?

In Innovyze's own words:

> Users must note that the flexible nature of the Ruby scripting language means that the language is almost infinitely flexible, ...

Too right it is! So over the past 2 nights, after work, I have been developing a WSDBFlags class. The class itself helps you read the flag data inside your databases, and wraps the flags in an easily accessible wrapper. Here's an example test script:

```ruby
require_relative("libs\\WSDBFlags.rb")

#print all flags
WSDBFlags.new.each do |flag|
    puts [flag.name,flag.desc,flag.defunct,flag.color].join(",")
end

#'S' for Surveyed, 'AS' for Assumed
standard_flags = ["#A", "#D", "#G","#I","#S","#V", "S", "AS"]

#Look for non standard flags:
puts "Non standard flags:"
(WSDBFlags.new.map {|flag| standard_flags.index(flag.name) ? flag : nil}).compact
.each do |flag|
    puts "#{flag.name} - #{flag.desc}"
end
```

And here's a slightly more complicated example:

```ruby
#Find and returns the counts of each flags used in DS_Invert, US_invert and Width fields of the hw_conduit table:
#e.g.
# 100 - S - Surveyed 
# 300 - AS - Assumed
require_relative("libs\\WSDBFlags.rb")
fields = ["ds_invert","us_invert","width"]
flags = WSDBFlags.new
fields.each do |field|
    puts "#{field}:"
    (row_objects("hw_conduit").group_by {|link| link["#{field}_flag"] })
    .each do |flag,links|
        puts "#{links.length.to_s.ljust(5)} - #{flag.ljust(3)} - #{(flags.search {|f| f.name == flag}).desc}"
    end
end
```

# Conclusion:

I hope you find this ruby library useful in your work!

The algorithm is still incomplete, and I am still finding issues with the current workings of the algorithm. Feel free to make a push request if you make the script more stable! As with all open source software, it might still be unstable!

It'd be a good idea to use the algorithm on a test table first, to get to know how it works / how to use it.

Finally, the code at the moment is quite messy despite it being as class based as possible. Ideally class IWDBHelper would be a full extension/ wrapper of the WSDatabase object. There are also still far more utilities which could be added which would be nice to have. For example, being able to iterate over user and shared custom actions would be a great addition to the IWDBHelper class.


# Disclaimer:

Due to the nature of this operation I cannot guarantee this class will work on your database. It should not cause database corruption, but I will not be held liable if it does, ensure you keep regular backups! Also bear in mind that it is quite possible that Innovyze intends to change the Wallaby 2 file format that this system relies upon. Therefore it is not certain whether this will break in future versions of ICM and it's also not certain that I'll have access to ICM, to fix the issue, when it finally does break. Hopefully Innovyze will add their own method for it in the future before changing the Wallaby 2 file format.

	
# How it works

The algorithm works by searching the workgroup database / standalone database for the following regex pattern:

```ruby
/flags.+id, description, defunct, color(?<data>(?:.|\s)*?)[\x00-\x08]/m
```

When the string is found, it can easily be parsed with ruby, as the string itself is just a regular CSV.

Currently, the class is intentionally built to only read the data. You cannot create new flags, modify existing flags or remove old flags with this library. This is intentional as I do not yet fully understand how the database changes when a change is made to the flags data. 

# Developer's notes

Currently the line we search for is actually more akin the following

```
flags.{4}id, description, defunct, color
```
	
where `.{4}` represents a 4 byte number which contains, I believe, the number of minutes since epoch of the model network. Testing shows that this figure is updated whenever a user attempts to change an existing flag or add a new one. Ultimately, I believe, this is the 'date flags were last modified' flag for the user flags data.

It may also be interesting knowing that flags are sorted alphabetically in the database.

Tests:

```
* With 2 new flags bytes = 1;0;0;0
* Add another and we get 4;0;0;0
* Another: 7;0;0;0
* Change an existing description --> 8;0;0;0
* Edit field but don't change anything --> 12;0;0;0
* Open flags info viewer, do nothing --> 12;0;0;0
* Edit field again --> 22;0;0;0	(was roughly 10 minutes later than last edit)
* --> Actually really does feel like a date. But minutes passed since creation of database.
* The maximum age of this flag is therefore: 255;255;255;255 (or 4, 294, 967, 295 minutes after epoch. (Or 8171.5 years after model creation). In hindsight though, this flag could be changed to any aribtrary value (or not at all!) to edit the flag fields.

* Global Prefs fails to read when editing fields. Assumed there is a length byte for Global prefs somewhere. --> Confirmed. Changing the internal data without changing the length causes no error
* ---> There appears to be a number of lines character. When adding 1 character to a file a [TAB] character is switched to a [LF] character. Byte offset: Substr(/"#A, \"Asset Data\""/.Position - 2388,1) The character before this character should always be a [EOT] character (as far as I can tell)
* -----> Not consistently a 2388 byte offset. This may also be a red herring.
```
