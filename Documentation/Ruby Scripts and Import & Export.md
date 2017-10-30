# Ruby In ODIC / ODXC
Version 2.01 27-Jan-2013 (updated for ICM 5.0 / InfoNet 5.0)

## INTRODUCTION

It is possible to customise the Open Data Import and Export Centres to some extent by writing scripts (small programs) in the Ruby programming language. 

The scripts must be written using a text editor external to the InfoWorks ICM / InfoNet software. It is possible to use Notepad but editors designed specifically for this process are more suitable. TextPad is a suitable such program, which offers useful highlighting when editing Ruby scripts, but there are others available.
Ruby scripts are conventionally given the 'rb' suffix e.g. 'myimport.rb', 'myexport.rb'.

### Loading The Scripts

Having written the script you should load it by hitting the […] button in the Script File box on the dialog:
 
If there are errors when the script is loaded they are displayed in a dialog e.g.
 
After changing the script, hit the 'Reload' button – the script will be reloaded and checked for errors again.

# Basic Mechanism

In both the importer and exporter the user needs to provide a Ruby class with a number of class methods (as opposed to instance methods). 
When used in the user interface as opposed to InfoNet Exchange, the classes must be named Importer for the Open Data Import Centre and Exporter for the Open Data Export Centre.

The methods must be methods of the class itself rather than methods of a base class.
Open Data Import Centre

The user should define a class Importer containing a number of methods with names of the form

```
OnBegin<tablename>
OnEnd<tablename>
OnBeginRecord<tablename>
OnEndRecord<tablename>
```

are called as follows:

* OnBegin<tablename> - before importing the table 	
* OnEnd<tablename> - after importing the table 
* OnBeginRecord<tablename> - before each record is processed. Specifically, this is called AFTER the data is read but before any processing is done. Processing in this case means the normal assignment of the import data to the InfoWorks ICM fields based on the field mapping set up on the Open Data Import Centre Dialog
* OnEndRecord<tablename> - after the normal assignment of the import data to the InfoWorks ICM fields BUT before the data is written to the master database. 

These methods have one parameter which is of class WSImporter. This object is used to set and get field values, choose whether to add or update or delete a record, whether to log a message and whether to abandon further import into the table.
Only some of these methods may be used in the OnBegin<table> and OnEnd<table> methods - see below.

The table names are the names which appear in the Select Table To Import Data into list on the Open Data Import Centre dialog but with any spaces in the name removed, for example

* Node
* Conduit
* 2DZone
* FlapValve

If you are using a sub-table e.g. Details for CCTV Surveys then the name of the subtable should follow the table name without any spaces e.g. CCTVSurveyDetails. 

## Using the methods
* OnBegin<tablename> - the primary purpose of OnBegin is to initialise values in class instance variables that are used later in the record. 
* OnBeginRecord<tablename> and OnEndRecord<tablename> - it makes little difference whether you do things in OnBeginRecord or OnEndRecord, except that
a) if you know you are going to abandon a record, you may as well do it in OnBeginRecord. This will speed up the import process 
b) if you set a field using the script that is also set by the normal field mapping, you must do this in OnEndRecord. Otherwise the field will be overwritten by the normal assignment 

# Instance methods of the WSImporter object
The following methods of the WSImporter object are used to control the import:

## writeRecord

### Purpose 
This is used to determine whether the record should be written.

### Syntax

```ruby
obj.writeRecord = false
```


## deleteRecord

### Purpose 
As writeRecord but used to determine whether the corresponding object should be deleted.

### Syntax

```ruby
obj.deleteRecord = true
```

## tableAbandoned

### Purpose 
This is used to determine whether the table should be abandoned i.e. no further records should be processed.

```ruby
obj.tableAbandoned = true
```

## logMessage

### Purpose 
Used to log a message.

### Syntax

```ruby
logMessage(message,type)
```

**message** - The text to display.

**type** - 'E', 'W' and 'I' for error, warning and information respectively. If the 2nd parameter is not one of these three strings, the message is treated as an error message. 

## []

### Purpose 
Used to get and set field values

### Syntax

```ruby
obj['user_number_1']=123
if(obj['my field 26']='D') logMessage("Where 'my field 26' is 'D'",'I')
```

Field names which are read refer to the names in the import data source, names which are written refer to field names in the InfoWorks network. If a column in the import layer has the same name as a column in the infoworks table, a 1 is appended to the end of it's name.

## message_box

### Purpose 

Displays a message box.

### Syntax

```ruby
message_box(text,options,icon)
```

**Text** – the text displayed

**Options** – must be nil or one of the following strings: ‘OK’, ’OKCancel’, ’YesNo’, ’YesNoCancel’. If the parameter is nil, then the OK and Cancel buttons are displayed.

**Icon** – must be nil or one of the following strings: ‘!’, ‘?’, ‘Information’. If the parameter is nil then the ‘!’ icon is used.

The method returns ‘Yes’,’No’,’OK’ or ‘Cancel’ as a string. 

You will typically want to use this in the OnBegin<tablename> methods and store the result, or something based on the result in a class variable for use in subsequent method calls. 

```
@setusernumbers=false
if obj.message_box(‘set user numbers?’,’YesNo’,’?’)==’Yes’
   @setusernumbers=true
end
```

If you want to use a cancel button and have this stop the import you should use the return value of the method in conjunction with the tableAbandoned= method e.g.

```
@setusernumbers=false
ret=obj.message_box('Do the thing?','YesNoCancel','?')
if ret=='Cancel'
	obj.tableAbandoned=true
elsif ret=='Yes'
	@setusernumbers=true
End
```

## input_box(prompt,title,default)

### Syntax

```ruby
input_box(prompt,title,default)
```

**Prompt** – the prompt text

**Title** – the title of the message box, if this is blank then the application’s default title will be displayed.

**Default** – the default value for the input, this is initially the value in the editable text box.

If OK is pressed, the value in the text box will be returned as a string, otherwise an empty string will be returned (in line with the equivalent VBScript function).

```ruby
class Importer
	def Importer.OnBeginNode(obj)
		@dels=''
		@delcount=0
	end
	def Importer.onEndNode(obj)
		if @dels==0
			obj.logMessage 'No records were deleted','E'
		else
			obj.logMessage @@dels,'I'
		end	
	end
	def Importer.onBeginRecordNode(obj)
		if obj['acton']=='D'
			obj.deleteRecord=true
			if @delcount>0
				@dels+=','
			else
				@dels='Deleted '
			end
			@dels+=obj['node_id']
			@delcount+=1
		end
	end
	def Importer.onEndRecordNode(obj)
	end
end
```

```ruby
class Importer
	def Importer.onBeginNode(obj)
		@@recordswritten=0
		@@recordsread=0
		@@skipnext=false
	end
	def Importer.onEndNode(obj)
	end
	def Importer.onBeginRecordNode(obj)
		@@recordsread+=1
		if @@skipnext
			obj.writeRecord=false
			@@skipnext=false
		else
			obj.writeRecord=true
			@@skipnext=true
		end
	end
	def Importer.onEndRecordNode(obj)
		obj['user_number_1']=123
		obj['user_text_1']='badger'	
		obj['user_text_2']=obj['node_type']+'stoat'+obj['system_type']
		obj['user_number_2']=obj['x'].to_f-obj['y'].to_f
		@@recordswritten+=1
		obj['user_number_3']=@@recordswritten
		obj['user_number_4']=@@recordsread
		if @@recordswritten==20
			obj.tableAbandoned=true
		end
	end
end
```

# Open Data Export Centre

The script mechanism for export is different from the script mechanism for imports. 

There are two things that can be done in the Open Data Export Centre.

1.	Filtering (i.e. restricting which records can be exported)
2.	Exporting calculated fields

The user should define a class in Ruby named Exporter. 

## Filtering

The filtering works in a similar fashion to the importer methods i.e. the names are determined by the table names. 

The methods are 

*	OnFilterStart<TableName> 
*	OnFilterRecord<TableName>
*	OnFilterBlob<TableName>

### Example 
```
OnFilterStartNode
OnFilterRecordNode
OnFilterBlobCCTVSurvey
```

The OnFilterStart method takes no parameters and returns no value. Its purposes is essentially to allow the user to set up data accessed for each record in the table e.g.

```ruby
	def Exporter.onFilterStartNode
		@myHash=Hash.new
		@myHash['Y']=0
		@myHash['F']=0
		@myHash['U']=0
	end
```

The OnFilterRecord method takes one parameter which is an object of class WSExporter, this has only one method which is used to the get the value of a field e.g. `obj[‘node_id’]`

The method should return true if the record should be exported, false otherwise e.g.

```ruby
def Exporter.onFilterRecordNode(obj)
    return @myHash.has_key?(obj['node_type'])
end
```

This method, combined with the OnFilterStart method above serve to only export data where the node_type field  is Y, F or U. 

The name 'OnFilterRecord' is a slight misnomer, because when arrays (also referred to as 'blobs' are exported) OnFilterRecord is called once for each object in the InfoWorks / InfoNet table, whereas OnFilterBlob is called for each row in the array e.g. for each detail in a CCTV survey.

OnFilterRecord takes 3 parameters
1.	The object parameter – of class WSExporter as above
2.	The index of the row in the array (starting at 1)
3.	The number of rows in the array

As with OnFilterRecord you should return true from OnFilterBlob if the line in the array should be exported, false otherwise. 

Exporting Calculated Fields
The class should contain a number of class methods taking one parameter. Only methods in the class, rather than contained in a base class can be used
You can export the value returned by one of these instance methods as a separate field by selecting Ruby in the Field Type column and then entering the name of the class method in the details column.
The object passed as a parameter into the method is of the class WSExporter, as noted above this has only one method [] which is used to get the value of a field e.g.
obj['node_id']

Example:

```ruby
class Exporter
	def Exporter.Hamster(obj)
		return  obj['node_id']+'xxx'
	end
	def Exporter.Penguin(obj)
		return 'yyy'+obj['x'].to_s+'zzz'+obj['y'].to_s
	end
end```

In array fields it is possible to get values for the current row of the array in this manner e.g. obj['details.code']

If you have an on filter method it is guaranteed that this will be called before the calculated fields, therefore you can set values in class variables in the filter method to use in the calculated field methods. 
Behaviour in InfoNet Exchange. In InfoNet Exchange, rather than using the fixed class names Importer and Exporter, the class is passed into the relevant method. 

In the methods odec_export_ex and odic_import_ex the class is set in the options 'hash' e.g `myhash['Callback Class']=MyClass`

This allows the user to use multiple classes in the same script.
