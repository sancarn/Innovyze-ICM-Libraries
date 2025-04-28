require 'tempfile'

class WSApplication
	#Create an alias for current_network in order to use it later
	singleton_class.send(:alias_method, :base_current_network, :current_network)
	
	#Overwrite existing class method. Return custom object.
	def self.current_network
		return STDWSOpenNetwork.new(self.base_current_network)
	end
	
	#Add script_dir method
	def self.script_dir
		File.dirname(self.script_file)
	end
end

class STDDelegate
	attr_accessor :oDelegate
	
	#Initialise with delegate object
	def initialize(oDelegate)
		@oDelegate = oDelegate
	end
	
	#When methods is called return both @network's methods as well as own
	def methods
		return (@oDelegate.methods).concat(super)
	end
	
	#If a method we call is missing, pass the call onto the object we delegate to:
	def method_missing(name,*args,&block)
		if @oDelegate.respond_to? name
			@oDelegate.send(name,*args,&block)
		else
			raise "Error: undefined method '#{name.to_s}' of #{self.to_s} and #{@oDelegate}."
		end
	end
	
	#Redefine respond_to to include both WSOpenNetwork and STDWSOpenNetwork
	def respond_to?(sym, include_private = false)
		@oDelegate.respond_to?(sym) || super(sym, include_private)
	end
end
	
	
class STDWSOpenNetwork < STDDelegate #Extends STDDelegate
	
	#After attempting to extend WSOpenNetwork class we get issues when calling the existing methods:
	#	WSApplication.current_network.run_SQL("","")
	#		> Error: wrong argument type STDWSOpenNetwork (expected Data)
	#	WSApplication.current_network.row_object_collection('_nodes')
	#		> Error: wrong argument type STDWSOpenNetwork (expected Data)
	#Which means that typically WSApplication is of class Data:
	#	> This is a recommended base class for C extensions using Data_Make_Struct or Data_Wrap_Struct, 
	#	  see README.EXT for details.
	#Makes sense... To solve our problem however we will just divert all missing methods to the network
	#object.
	
	#Initialise
	def initialize(network)
		super(network)
		@model_object = nil
		return self
	end
	
	def row_object_collection(type)
		rows = []
		@oDelegate.row_objects(type)
	end
	
	def row_object_collection_selection(type)
		rows = []
		@oDelegate.row_object_collection_selection(type).each {|ro| rows << ro}
	end
	
	
	def odec_export_ex_WIP(format, cfg, options, *args)
		#cfg can either be a file or a hash
		#	odec_export_ex('MIF', {"node" => ["node_id","ground_level","user_text_1"]})
		#the hash will be converted to a hash
		cfg = _config(cfg)
		@oDelegate.odec_export_ex(format,cfg.path,options,*args)
		cfg.close(true)  #Unlink tempfile/Close file
	end
	
	def odec_import_ex_WIP(format, cfg, options, *args)
		#see odec_import_ex_WIP
		cfg = _config(cfg)
		@oDelegate.odec_export_ex(format,cfg.path,options,*args)
		cfg.close(true)  #Unlink tempfile/Close file
	end
	
	def _config(cfg)
		#private method for parsing the config supplied
		if cfg.is_a?(Hash)
			file = Tempfile.new("ICM_cfg")
			file.write(_configParseHash(Hash))
			file.close
			return file
		elsif cfg.is_a?(String)
			if File.exist?(cfg)
				file=File.new(cfg)
				file.close
				return file
			else	#Assume config as string
				file = Tempfile.new("ICM_cfg")
				file.write(cfg)
				file.close
				return file
			end
		end
	end
	
	def _configParseHash(hash)
		#private method for parsing config hashes.
		#returns ICM config file contents as string.
		#example:{"node":["":{"Type"=>"Special","Field"=>"NetworkID"}]}
		#       ==> "DBX001\nNode,{{,Special,Default,Default,Default,NetworkID}},"
	end
	
    # Not required as of ICM 2023.1.0
	# #Returns the name of the open network
	# def model_object()
	# 	if @model_object != nil
	# 		return @model_object 
	# 	end
		
	# 	#TODO: Make temporary selection list to reload selection after ruby call.
		
	# 	@oDelegate.clear_selection
	# 	@oDelegate.row_objects('_Nodes')[0].selected=true
		
	# 	#Setup temporary files for export
	# 	cfg = Tempfile.new("ICM_cfg")
	# 	csv = Tempfile.new("ICM_csv")
	# 	cfg.write("DBX001\nNode,{{,Special,Default,Default,Default,NetworkID}},")
	# 	cfg.close
	# 	csv.close
		
	# 	#Get network ID from exported CSV
	# 	@oDelegate.odec_export_ex('CSV',cfg.path,{"Export Selection" => true},'Node',csv.path)
	# 	networkID = csv.read.to_i
		
	# 	#Remove temporary files
	# 	cfg.unlink
	# 	csv.unlink
		
	# 	#TODO: Reload and delete temporary selection list.

	# 	#Get model network
	# 	iwdb = WSApplication.current_database
		
	# 	#Set model_object for future calls
	# 	@model_object = iwdb.model_object_from_type_and_id('Model Network',networkID)
		
	# 	return @model_object
	# end
	
	def is_committed?()
		#TODO: Make temporary selection list to reload selection after ruby call.
		
		@oDelegate.clear_selection
		
		#Create temporary file
		file = Tempfile.new("ICM_on")
		file.close
		
		#Try to export selected network, if fails then network still has uncomitted changes.
		begin
			@oDelegate.snapshot_export_ex(file.path,{"SelectedOnly"=> true})
			retVar = true
		rescue
			retVar = false
		end
		
		#TODO: Reload and delete temporary selection list.
		
		file.unlink
		return retVar
	end
	
	def selection(type="")
		if type == ""
			@oDelegate.table_names.each do |table|
				roc = STDRowObjectCollection.new([])
				roc.concat(@oDelegate.row_object_collection_selection(table))
				return roc
			end
		else
			return STDRowObjectCollection.new(@oDelegate.row_object_collection_selection(type))
		end
	end
	
	def mapinfoLayers
		#@oDelegate.row_object("hw_prefs","MapXtremeLayers").Memo #=> To Array
		#[{},{},{},...]
	end
	
	def mapinfoLayers = (arr)
		#_.net.row_object("hw_prefs","MapXtremeLayers").Memo = ...
	end
	
	private :_config, :_configParseHash
end

class STDRowObjectCollection < STDDelegate
	def initialize(roc)
		if roc.is_a? Array
			super(roc)
		else
			arr = []
			arr = roc.each {|ro| arr << getObject(ro)} 
			super(arr)
		end
	end
	
	def concat(roc)
		if roc.is_a? Array
			@oDelegate.concat(roc)
		else
			arr = []
			arr = roc.each {|ro| arr << getObject(ro)} 
			@oDelecate.concat(arr)
		end
	end
	
	def getObject(ro)
		if ro.is_a? WSLink
			return STDLink.new(ro)
		elsif ro.is_a? WSNode
			return STDNode.new(ro)
		elsif ro.is_a? WSRowObject && ro.table == "hw_subcatchment"
			return STDSubcatchment.new(ro)
		else
			return STDRowObject.new(ro)
		end
	end
end

class STDRowObject < STDDelegate
	def initialize(ro)
		super(ro)
		return self
	end
	def select
		oDelegate.selected = true
	end
	def deselect
		oDelegate.selected = false
	end
end

class STDLink < STDRowObject
	def initialize(link)
		if link.is_a? WSLink
			super(link)
			return self
		else
			return nil
		end
	end
end

class STDNode < STDRowObject
	def initialize(node)
		if node.is_a? WSNode
			super(node)
			return self
		else
			return nil
		end
	end
end

class STDSubcatchment < STDRowObject
	def initialize(sc)
		if sc.is_a? WSRowObject && sc.table == "hw_subcatchment"
			super(sc)
			return self
		else
			return nil
		end
	end
end











# RESEARCH:
#	_.net.each {|ro| p ro.id.to_s + "    ,    " + ro.table_info.name.to_s}
#returns all objects in the numbat table and the table that they come from. There are a few non-standard objects here:
#	ARCH                                       ,    hw_shape
#	ARCHSPRUNG                                 ,    hw_shape
#	CIRC                                       ,    hw_shape
#	CNET                                       ,    hw_shape
#	EGG                                        ,    hw_shape
#	EGG2                                       ,    hw_shape
#	OEGB                                       ,    hw_shape
#	OEGN                                       ,    hw_shape
#	OREC                                       ,    hw_shape
#	OT1:1                                      ,    hw_shape
#	OT1:2                                      ,    hw_shape
#	OT1:4                                      ,    hw_shape
#	OT1:6                                      ,    hw_shape
#	OT2:1                                      ,    hw_shape
#	OT4:1                                      ,    hw_shape
#	OU                                         ,    hw_shape
#	OVAL                                       ,    hw_shape
#	RECT                                       ,    hw_shape
#	UTOP                                       ,    hw_shape
#	1                                          ,    hw_runoff_surface
#	10                                         ,    hw_runoff_surface
#	2                                          ,    hw_runoff_surface
#	20                                         ,    hw_runoff_surface
#	21                                         ,    hw_runoff_surface
#	3                                          ,    hw_runoff_surface
#	4                                          ,    hw_runoff_surface
#	40                                         ,    hw_runoff_surface
#	46                                         ,    hw_runoff_surface
#	47                                         ,    hw_runoff_surface
#	48                                         ,    hw_runoff_surface
#	5                                          ,    hw_runoff_surface
#	6                                          ,    hw_runoff_surface
#	9                                          ,    hw_runoff_surface
#	99                                         ,    hw_runoff_surface
#	ST1                                        ,    hw_land_use
#	ST2                                        ,    hw_land_use
#	ST3                                        ,    hw_land_use
#	ST4                                        ,    hw_land_use
#	ST5                                        ,    hw_land_use
#	ST6                                        ,    hw_land_use
#	ST7                                        ,    hw_land_use
#	ST8                                        ,    hw_land_use
#	ST9                                        ,    hw_land_use
#	NONE                                       ,    hw_headloss
#	NORMAL                                     ,    hw_headloss
#	HIGH                                       ,    hw_headloss
#	FIXED                                      ,    hw_headloss
#	FHWA                                       ,    hw_headloss
#	""                                         ,    hw_sim_parameters
#	""                                         ,    hw_manhole_defaults
#	""                                         ,    hw_conduit_defaults
#	""                                         ,    hw_subcatchment_defaults
#	""                                         ,    hw_large_catchment_parameters
#	""                                         ,    hw_wq_params
#	""                                         ,    hw_washoff
#	""                                         ,    hw_channel_defaults
#	""                                         ,    hw_rtc
#	""                                         ,    hw_snow_parameters
#	""                                         ,    hw_2d_zone_defaults
#	""                                         ,    hw_river_reach_defaults
#	{D58813B0-C0EB-4B62-9C18-11AF437AF47B}     ,    hw_prunes
#	MigratedFrom                               ,    hw_prefs		#->_.net.row_object("hw_prefs","MigratedFrom").memo #=> 523-127_Rainworth_SMS_Warsop Ln SCA_#03
#	geoplan_mapxtreme_address_layer            ,    hw_prefs
#	geoplan_mapxtreme_address_layer_field      ,    hw_prefs
#	geoplan_mapxtreme_sat_layer                ,    hw_prefs
#	geoplan_mapxtreme_sat_layer_field1         ,    hw_prefs
#	geoplan_mapxtreme_sat_layer_field2         ,    hw_prefs
#	geoplan_mapxtreme_sat_layername            ,    hw_prefs
#	geoplan_persons_per_address                ,    hw_prefs
#	geoplan_sat_pervious_surface               ,    hw_prefs
#	NETWORKSIMPLIFICATION_MERGEADDNOTREPLACE   ,    hw_prefs
#	NETWORKSIMPLIFICATION_MERGEINCLUDEADD      ,    hw_prefs
#	NETWORKSIMPLIFICATION_MERGEINCLUDEAREA     ,    hw_prefs
#	NETWORKSIMPLIFICATION_MERGEINCLUDECOND     ,    hw_prefs
#	NETWORKSIMPLIFICATION_MERGESHCHDS          ,    hw_prefs
#	NETWORKSIMPLIFICATION_MERGESHCHUS          ,    hw_prefs
#	NETWORKSIMPLIFICATION_MERGEUSDS            ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNEADDNOTREPLACE   ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNEDESELECTLINKS   ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNEDESELECTNODES   ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNEINCLUDEADD      ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNEINCLUDEAREA     ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNEINCLUDECOND     ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNESELECTNODES     ,    hw_prefs
#	NETWORKSIMPLIFICATION_PRUNESHCHDS          ,    hw_prefs
#	NETWORKSIMPLIFICATION_USERFLAG             ,    hw_prefs
#	polygons                                   ,    hw_prefs
#	STORAGECOMPENSATION_ADDNOTREPLACE          ,    hw_prefs
#	STORAGECOMPENSATION_ADDSUBCATCHBASEFLOW2   ,    hw_prefs
#	STORAGECOMPENSATION_DWELLINGSPERHECT       ,    hw_prefs
#	STORAGECOMPENSATION_FLOWPERHEAD            ,    hw_prefs
#	STORAGECOMPENSATION_MAXCONNCALC            ,    hw_prefs
#	STORAGECOMPENSATION_MAXCONNLENGTH          ,    hw_prefs
#	STORAGECOMPENSATION_METHOD                 ,    hw_prefs
#	STORAGECOMPENSATION_MINCONNLENGTH          ,    hw_prefs
#	STORAGECOMPENSATION_PAVEDAREAINDEX         ,    hw_prefs
#	STORAGECOMPENSATION_PAVEDAREAPERCONN       ,    hw_prefs
#	STORAGECOMPENSATION_PERSONSPERDWELL        ,    hw_prefs
#	STORAGECOMPENSATION_REDISTRIBUTEDS         ,    hw_prefs
#	STORAGECOMPENSATION_REDISTRIBUTEUS         ,    hw_prefs
#	STORAGECOMPENSATION_REDISTRIBUTIONUSDS     ,    hw_prefs
#	STORAGECOMPENSATION_ROOFEDAREAINDEX        ,    hw_prefs
#	STORAGECOMPENSATION_ROOFEDAREAPERCONN      ,    hw_prefs
#	STORAGECOMPENSATION_TYPCONNDIAM            ,    hw_prefs
#	STORAGECOMPENSATION_TYPCONNFILL            ,    hw_prefs
#	STORAGECOMPENSATION_USERFLAG               ,    hw_prefs
#	MapXtremeLayers                            ,    hw_prefs
#	geoplan_mapxtreme_projection               ,    hw_prefs
#	geoplan_mapxtreme_projection_bounds        ,    hw_prefs
#	GeoTransformMX                             ,    hw_prefs
#	""                                         ,    hw_validation_result
#
# ACCESSING MAPXTREME LAYERS:
#    _.net.row_object("hw_prefs","MapXtremeLayers").methods - Object.methods
#		>[:[], :[]=, :autoname, :category, :contains?, :delete, :field, :id, :id=, :is_inside?, :navigate, :navigate1, :objects_in_polygon, :selected, :selected?, :selected=, :table, :table_info, :write, :method_missing]
#	_.net.row_object("hw_prefs","MapXtremeLayers").table_info.description #==> Network preference
#
#   _.net.field_names("hw_prefs")
#       > ["Name", "Double", "Memo", "Type"]
#_.net.row_object("hw_prefs","MapXtremeLayers").Name	#=> MapXtremeLayers
#_.net.row_object("hw_prefs","MapXtremeLayers").Double	#=> nil
#_.net.row_object("hw_prefs","MapXtremeLayers").Memo
#	>   Layer List Version 1.00
#       MapXtreme
#       C:\Users\jwa\Desktop\TBD\ModeledSPS.TAB,C:\Users\jwa\Desktop\TBD\IndexVsRownum.TAB
#       layer_index,layer_type,visible,zoom_min,zoom_max,scale_min,scale_max,pathname,coordsys_srs,alt_coordsys_name,wms_layers,wms_srs,wms_map_format,wms_transparent,wms_colour,selectable,editable,enabled,apply_style_override,area_fill_pattern,area_fill_back_colour,area_fill_fore_colour,area_fill_transparent,area_bnd_pattern,area_bnd_line_width_value,area_bnd_line_width_unit,area_bnd_color,area_bnd_interleaved,line_pattern,line_width_value,line_width_unit,line_color,line_interleaved,symbol_code,symbol_point_size,symbol_colour,symbol_font_name,symbol_font_point_size,symbol_font_fore_colour,symbol_font_back_colour,symbol_font_italic,symbol_font_bold,symbol_font_all_caps,symbol_font_shadow,symbol_font_expanded,symbol_font_text_effect,symbol_font_text_decoration,symbol_font_angle,symbol_bitmap_name,symbol_bitmap_style,text_font_name,text_font_point_size,text_font_fore_colour,text_font_back_colour,text_font_italic,text_font_bold,text_font_all_caps,text_font_shadow,text_font_expanded,text_font_text_effect,text_font_text_decoration,CRActive,CRField,CRCount,CRColourStart,CRColourEnd,CRNumBreaks,VRActive,VRField,VRNumValues,LRActive,LRField,LRAlignment,LRMaxLabels,LRLabelOffset,LRAllowDuplicateText,LRAllowOverlappingText,LRLabelPartialObjects,LRLabelCalloutLineType,LRLabelRotationType,LRLabelAngle,LRLabelLinePattern,LRLabelLineWidthValue,LRLabelLineWidthUnit,LRLabelLineColour,LRLabelLineInterleaved,LRLabelTextFontName,LRLabelTextFontPointSize,LRLabelTextFontForeColor,LRLabelTextFontBackColor,LRLabelTextFontItalic,LRLabelTextFontBold,LRLabelTextFontAllCaps,LRLabelTextFontShadow,LRLabelTextFontExpanded,LRLabelTextFontTextEffect,LRLabelTextFontTextDecoration
#       0,0,1,0,0,0,0,C:\Users\jwa\Desktop\TBD\ModeledSPS.TAB,"mapinfo:coordsys 8,79,7,-2,49,0.9996012717,400000,-100000",,,,,0,0,1,0,1,0,-1,0,0,1,-1,0.000000,0,0,0,-1,0.000000,0,0,0,34,8.000000,-16777216,MapInfo Symbols,8.000000,0,0,0,0,0,0,0,0,0,0,,0,,0.000000,0,0,0,0,0,0,0,0,0,0,,0,0,0,0,0,,0,0,,0,1000,0,0,0,0,0,2,0.000000,0,1.000000,0,0,0,,0.000000,0,0,0,0,0,0,0,0,0
#       1,0,1,0,0,0,0,C:\Users\jwa\Desktop\TBD\IndexVsRownum.TAB,"mapinfo:coordsys 1,0",,,,,0,0,1,0,1,0,-1,0,0,1,-1,0.000000,0,0,0,-1,0.000000,0,0,0,34,8.000000,-16777216,MapInfo Symbols,8.000000,0,0,0,0,0,0,0,0,0,0,,0,,0.000000,0,0,0,0,0,0,0,0,0,0,,0,0,0,0,0,,0,0,,0,1000,0,0,0,0,0,2,0.000000,0,1.000000,0,0,0,,0.000000,0,0,0,0,0,0,0,0,0
#_.net.row_object("hw_prefs","MapXtremeLayers").Type    #=> 3

# ACCESSING PRUNES:
#    _.net.field_names("hw_prunes")
#        > ["prune_id", "date", "system_type", "point_count_array", "point_array"]
#    _.net.row_objects("hw_prunes")[0].point_array
#    _.net.row_objects("hw_prunes")[0].point_count_array
#    require 'date'; _.net.row_objects("hw_prunes")[0].date #=> 2003 10 14 ...







#_.net.row_object("hw_prefs","MapXtremeLayers").Memo