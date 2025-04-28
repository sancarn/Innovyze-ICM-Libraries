require_relative 'lib/WSModelWalker.rb'

#Get all outfalls downstream of a specific node
#@param link - The link object to get outfalls for.
#@return - An array of outfall objects associated with the node.
#@remark - This function filters the links to only include those that are outfalls.
#@note - The function uses the `navigate` method to get all downstream links and then filters them based on their type.
def getOutfalls(link)
    outfalls = link.navigate("all_ds_links").select do |link|
        link.ds_node.node_type.downcase == "outfall"
    end.map do |link|
        link.ds_node
    end
    return outfalls
end

def getManholeFloodLevel(node)
    if node.flood_level < node.ground_level
        flood_level = node.flood_level
    else
        flood_level = node.ground_level
    end
end

# Get the spill level of a link based on its type.
#@param link - The link object to get the spill level for.
#@return double - The spill level of the link.
#@remark -
#List of link types with their relevant spill levels:
#    Culvert inlet: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-136730D6-89AB-463B-83B9-2D360D7ED611
#        * CLVIN - `invert`
#    Culvert outlet: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-138333F9-EAD9-45C4-BA0D-EF63AC2855CF
#        * CLVOUT  - `invert`
#    Flap: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-1418E57B-C132-48F6-949B-162347F5684F
#        * FLAP - `invert`
#    Flume: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-14291F05-296C-4FED-B552-40DBE1DFC915
#        * RFLUME - `invert`
#        * TFLUME - `invert`
#        * UFLUME - `invert`
#    Inline Bank: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-15BB6CD3-E42B-446A-B3EF-817398C4F082
#        * IBANK - `crest`                    (?) (or might be via bank level in section data...??)
#    Irregular weir: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-15CACB65-3E7B-4941-8F4A-58EFAD679531
#        * IRWEIR  `crest`                    (?)
#    Orifice: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-19883D0E-582D-4387-AA21-ADE9E3ABB117
#        * ORIFIC - `invert`
#        * VLDORF - `invert`
#    Screen: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-1D701555-E038-42F8-88DC-D0130B380403
#        * SCREEN  - `crest`
#    Syphon: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-1E09A6F4-BB2D-4838-B174-AC042869C35F
#        * SIPHON - `crest`
#    Sluice: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-1E168695-5D06-4BE4-80AD-00D2B9DBE6C9
#        * SLUICE - Standard vertical sluice gate - `invert`
#        * VSGATE - Variable vertical sluice gate - `invert`
#        * RSGATE - Standard radial sluice gate - `invert`
#        * VRGATE - Variable radial sluice gate - `invert`
#    Weir: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-2200B2A4-0C87-42C4-8A8A-4AE5C7C3E4B0
#        * WEIR - Weir - `crest`
#        * VCWEIR - Variable crest weir - `minimum_elevation` || `crest`
#        * VWWEIR - Variable width weir - `crest`
#        * COWEIR - Contracted weir - `crest`
#        * VNWEIR - V-Notch weir - `crest`
#        * TRWEIR - Trapezoidal weir - `crest`
#        * BRWEIR - Round nose broad crested weir - `crest`
#        * GTWEIR - Gated weir - `minimum_elevation` || `crest`
#    Pumps: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-1B21FE58-FEE0-49A1-86F4-8B019D2A76A8
#        * FIXPMP - Fixed discharge pump           - Starts pumping at On level  - `switch_on_level`
#        * VSPPMP - Variable speed pump (RTC)      - Starts pumping at On level  - `switch_on_level`
#        * SCRPMP - Archimedean screw pump         - Starts pumping at On level  - `switch_on_level`
#        * ROTPMP - Rotodynamic pump               - Starts pumping at On level  - `switch_on_level`
#        * VFDPMP - Variable frequency drive pump  - Starts pumping at On level  - `switch_on_level` 
#    User controls: https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-20B61042-14EE-4450-907B-C6C32C996B25
#        * COMPND - Compound orifice or weir - `start_level`
#        * VORTEX - Example: Hydrobrake - `start_level`
def getSpillLevel(link)
    case link.link_type.upcase
    #Pumped storm overflow spill
    when "FIXPMP", "VSPPMP", "SCRPMP", "ROTPMP", "VFDPMP"
        link.switch_on_level
    #User control spill
    when "COMPND", "VORTEX"
        link.start_level
    #Spill by crest
    when "IBANK", "IRWEIR", "SCREEN", "SIPHON", "WEIR", "VCWEIR", "VWWEIR", "COWEIR", "VNWEIR", "TRWEIR", "BRWEIR", "GTWEIR"
        link.crest
    #When conduit utilised as a spill we use the greatest invert level
    when "COND"
        link.us_invert > link.ds_invert ? link.us_invert : link.ds_invert
    #Orifice/Conduit/Flume/Flap valve/etc. spills
    else #orifice, flume, rflume, sluice, vsgate, flap, CLVIN, CLVOUT
        link.invert
    end
end

# Find all pumping stations in the network (represented as pump objects) and their flood levels.
#@param network - The network object to get the pumping stations from.
#@return - A hash containing the network name, date, and an array of pumping stations with their flood levels.
def getSPSFloodLevelData(network)
    allSPS = network.row_objects("hw_pump").map do |pump_link|
        #Find all sewer network upstream of the pumping station
        feeding_network = WSModelWalker.new(pump_link).upstream_trace_until do |link, walker| 
            link.id != walker.start.id && (link.link_type[/pmp/i] || link.us_node.us_links.length == 0)
        end
        
        # Find the minimum level of all of the following:
        # 1. The flood level of the pumping station itself
        # 2. Upstream manhole flood levels
        # 3. All CSO spill levels
        
        pump_data = {
            "type"=>"chamber", 
            "flood_level" => getManholeFloodLevel(pump_link.us_node), 
            "x"=> pump_link.us_node.x, 
            "y"=> pump_link.us_node.y,
            "id"=> pump_link.us_node.id
        }

        #Get all manholes and their flood levels
        manholes = feeding_network.map do |link|
            node = link.us_node
        end.select do |node|
            #Filter out sealed manholes as these do not flood
            node.flood_type.downcase != "sealed"
        end.map do |node|
            {"type"=>"manhole", "flood_level"=> getManholeFloodLevel(node), "x"=> node.x, "y"=> node.y, "id"=> node.id}
        end

        #Get all CSOs and their spill levels
        # CSOs defined as those that have more outfalls than the pumping station itself
        sps_outfalls = getOutfalls(pump_link)

        #Assumes that CSOs have at least one incoming pipe.
        csos = feeding_network.select do |link|
            getOutfalls(link).length > sps_outfalls.length
        end.map do |link|
            link.ds_node
        end

        #Find the spills themselves
        feeding_network_ids = feeding_network.map {|link| link.id }
        spills = csos.map do |cso_node|
            #Select links not in feeding network
            link_spill_levels = cso_node.navigate("ds_links").select do |link|
                !feeding_network_ids.include?(link.id)
            end.map {|link| getSpillLevel(link) }
            
            {"type"=>"spill", "flood_level" => link_spill_levels.min, "x"=> cso_node.x, "y"=> cso_node.y, "id"=> cso_node.id}
        end

        flooding_levels = [pump_data] + manholes + spills

        #Debugging:
        flooding_levels.each do |flooding_level|
            if flooding_level["flood_level"].nil?
                puts "Flood level is nil for #{flooding_level["type"]} with id #{flooding_level["id"]}"
            end
        end

        #Find the minimum flood level of all flooding levels
        min_level = flooding_levels.min_by do |flooding_level|
            flooding_level["flood_level"] || Float::INFINITY
        end["flood_level"]

        {
            "x" => pump_data["x"],
            "y" => pump_data["y"],
            "flood_level" => min_level,
            "data" => flooding_levels
        }
    end

    reportData = {
        "network" => network.model_object.name,
        "date" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        "sps" => allSPS
    }

    return reportData

end