require 'ostruct'
require 'json'

module OpenAudit
  def getRecursiveOStruct(hash)
    hash.each_with_object(OpenStruct.new) do |(key, val), memo|
      memo[key] = val.is_a?(Hash) ? getRecursiveOStruct(val) : val
    end  
  end

  RuleTypes = {
    :error => {
      :color => "rgb(251, 158, 158)",
      :font_color => "#000000",
      :icon => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><g transform="matrix(.99999 0 0 .99999-58.37.882)" enable-background="new" id="g13" style="fill-opacity:1"><circle cx="82.37" cy="23.12" r="24" fill="url(#0)" id="circle9" style="fill-opacity:1;fill:#dd3333"/><path d="m87.77 23.725l5.939-5.939c.377-.372.566-.835.566-1.373 0-.54-.189-.997-.566-1.374l-2.747-2.747c-.377-.372-.835-.564-1.373-.564-.539 0-.997.186-1.374.564l-5.939 5.939-5.939-5.939c-.377-.372-.835-.564-1.374-.564-.539 0-.997.186-1.374.564l-2.748 2.747c-.377.378-.566.835-.566 1.374 0 .54.188.997.566 1.373l5.939 5.939-5.939 5.94c-.377.372-.566.835-.566 1.373 0 .54.188.997.566 1.373l2.748 2.747c.377.378.835.564 1.374.564.539 0 .997-.186 1.374-.564l5.939-5.939 5.94 5.939c.377.378.835.564 1.374.564.539 0 .997-.186 1.373-.564l2.747-2.747c.377-.372.566-.835.566-1.373 0-.54-.188-.997-.566-1.373l-5.939-5.94" fill="#fff" fill-opacity=".842" id="path11" style="fill-opacity:1;fill:#ffffff"/></g></svg>'
    },
    :warn => {
      :color => "rgb(246, 255, 187)",
      :font_color => "#000000",
      :icon => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 123.996 123.996" fill="#e4e401"><g><path d="M9.821,118.048h104.4c7.3,0,12-7.7,8.7-14.2l-52.2-92.5c-3.601-7.199-13.9-7.199-17.5,0l-52.2,92.5 C-2.179,110.348,2.521,118.048,9.821,118.048z M70.222,96.548c0,4.8-3.5,8.5-8.5,8.5s-8.5-3.7-8.5-8.5v-0.2c0-4.8,3.5-8.5,8.5-8.5 s8.5,3.7,8.5,8.5V96.548z M57.121,34.048h9.801c2.699,0,4.3,2.3,4,5.2l-4.301,37.6c-0.3,2.7-2.1,4.4-4.6,4.4s-4.3-1.7-4.6-4.4 l-4.301-37.6C52.821,36.348,54.422,34.048,57.121,34.048z"/></g></svg>'
    },
    :info => {
      :color => "rgb(173, 191, 255)",
      :font_color => "#000000",
      :icon => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600"><g transform="translate(0,-452.36218)"><path d="m 569.99987,752.36218 a 270,269.99977 0 1 1 -539.99974,0 270,269.99977 0 1 1 539.99974,0 z" style="fill:#005ec8;fill-opacity:1;fill-rule:nonzero;stroke:none"/><g transform="translate(-467.71592,-275.82467)"><path d="m 807.21592,973.1185 0,190 22,0 0,40 -122.8789,0.1367 0,-40 20.87891,-0.1367 0,-160 -20.87891,0.1367 -0.12109,-30.1367 c 39.86069,0.2304 61.02963,0.046 100.99999,0 z" id="polygon26" style="fill:#ffffff;stroke:none"/><circle cx="31" cy="17" r="4" transform="matrix(9.9999996,0,0,9.9999996,457.71594,723.11851)" style="fill:#ffffff;stroke:none"/></g></g></svg>'
    }
  }
  
  class Engine
    def initialize(customRules=[],customRuleTypes={}, customConfig={})
      @rules = OpenAudit::Rules.clone().concat(customRules)
      @ruleTypes = OpenAudit::RuleTypes.merge(customRuleTypes)
      @config = getRecursiveOStruct(JSON.parse(File.read("config.json")).merge(customConfig))
    end
    
    #
    #@returns Array<Result>
    def run(net=nil)
      @tableCache = {}
      net ||= WSApplication.current_network
      result = {
        :ruleTypes = @ruleTypes,
        :config = @config,
        :results = []
      }

      @rules.each do |rule|
        #Cache table objects
        @tableCache[rule[:table]] ||= net.row_objects(rule[:table])
        
        @tableCache[rule[:table]].select() {|row| rule[:exp].call(@config, row, net)}.each do |row|
          result[:results].push({
            :type    => rule[:type],
            :table   => rule[:table],
            :id      => row.id,
            :message => rule[:message].call(config),
            :short   => rule[:short].call(config)
          })
        end
        
      end
    end
  end

  Rules = [
    {
      :type    => :error,
      :table   => "_nodes",
      :message => ->(config){"This manhole has no upstream or downstream links."},
      :short   => ->(config){"This is an Isolated Node"},
      :exp     => ->(config, node, net){node.us_links.length == 0 && node.ds_links.length == 0},
    },
    {
      :type    => :error,
      :table   => "_nodes",
      :message => ->(config){"This manhole is at the end of the system but is not of type 'outfall'."},
      :short   => ->(config){"Non outfall Terminal Node"},
      :exp     => ->(config, node, net){node.ds_links.length == 0 & node.us_links.length > 0 & node.node_type.downcase != "outfall"},
    },
    {
      :type    => :error,
      :table   => "_nodes",
      :message => ->(config){"This manhole's ground level is not defined"},
      :short   => ->(config){"Missing ground Level"},
      :exp     => ->(config, node, net){!node.ground_level},
    },
    {
      :type    => :error,
      :table   => "_nodes",
      :message => ->(config){"This manhole's ground level is 0"},
      :short   => ->(config){"Ground Level 0"},
      :exp     => ->(config, node, net){node.ground_level == 0},
    },
    {
      :type    => :error,
      :table   => "_nodes",
      :message => ->(config){"This manhole's chamber area is not defined"},
      :short   => ->(config){"Missing Chamber Area"},
      :exp     => ->(config, node, net){!node.chamber_area},
    },
    {
      :type    => :error,
      :table   => "_nodes",
      :message => ->(config){"This manhole's plan area is not defined"},
      :short   => ->(config){"Missing Shaft Area"},
      :exp     => ->(config, node, net){!node.shaft_area},
    },
    {#TODO: Complete
      :type    => :warn,
      :table   => "_nodes",
      :message => ->(config){"Break nodes were only ever intended for use in rising mains, because they do not attenuate the flow. Break nodes should not be used for any other purpose."},
      :short   => ->(config){"Break node applied in a non-pump link. Potential initalisation issue."},
      :exp     => ->(config, node, net){false},
    },
    {
      :type    => :warn,
      :table   => "_nodes",
      :message => ->(config){"This manhole's flood_level is less than the ground_level."},
      :short   => ->(config){"Flood Level < Ground Level"},
      :exp     => ->(config, node, net){node.flood_level < node.ground_level},
    },
    {
      :type    => :warn,
      :table   => "_nodes",
      :message => ->(config){"This manholes floodable area is less than the minimum."},
      :short   => ->(config){"Floodable area < min (give Value)"},
      :exp     => ->(config, node, net){node.floodable_area < config.manhole.floodableArea.min && node.flood_type.downcase == "stored"},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"This manholes has additional shaft area."},
      :short   => ->(config){"Additional Chamber Area Applied"},
      :exp     => ->(config, node, net){node.shaft_area_additional > 0},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"This manholes has additional chamber area."},
      :short   => ->(config){"Additional Shaft Area Applied"},
      :exp     => ->(config, node, net){node.chamber_area_additional > 0},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"This manhole is outside of a subcatchment."},
      :short   => ->(config){"Node outside Subcatchment"},
      :exp     => ->(config, node, net){(net.search_at_point(node.x,node.y,0,"hw_subcatchment")||"").length == 0},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"Multiple subcatchments are draining to this node."},
      :short   => ->(config){"Multiple subcatchments drain to this node"},
      :exp     => ->(config, node, net){
        if !$subcatchment_groups
          $subcatchment_groups = net.row_objects("hw_subcatchment").group_by {|sc| sc.node_id}
        end
        $subcatchment_groups[node.id].length > 1
      },
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"This manhole's chamber area is greater than #{config.manholes.chamberArea.max}m^2."},
      :short   => ->(config){"Chamber Area > #{config.manholes.chamberArea.max}m2"},
      :exp     => ->(config, node, net){node.node_type.downcase == "manhole" & node.chamber_area > config.manholes.chamberArea.max},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"This manhole's shaft area is greater than #{config.manholes.shaftArea.max}m^2."},
      :short   => ->(config){"Shaft Area > #{config.manholes.shaftArea.max}m2"},
      :exp     => ->(config, node, net){node.node_type.downcase == "manhole" & node.shaft_area > config.manholes.shaftArea.max},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"This manhole is of type 'Break' which may affect stability."},
      :short   => ->(config){"Break Node"},
      :exp     => ->(config, node, net){node.node_type.downcase == "break"},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"This manhole has steep flood cones."},
      :short   => ->(config){"Steep flood cone"},
      :exp     => ->(config, node, net){
        node.node_type.downcase == "stored" & (
          ((node.floodable_area * node.flood_area_1 / node.flood_depth_1) < config.manholes.complex.floodConeCheck) || 
          ((node.floodable_area * node.flood_area_2 / node.flood_depth_2) < config.manholes.complex.floodConeCheck)
        )
      },
    },
    {
      :type    => :error,
      :table   => "_links",
      :message => ->(config){"This pipe is missing an upstream node."},
      :short   => ->(config){"Missing US Node"},
      :exp     => ->(config, link, net){!link.us_node},
    },
    {
      :type    => :error,
      :table   => "_links",
      :message => ->(config){"This pipe is missing a downstream node."},
      :short   => ->(config){"Missing DS Node"},
      :exp     => ->(config, link, net){!link.ds_node},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has no upstream invert."},
      :short   => ->(config){"Missing US invert"},
      :exp     => ->(config, link, net){!link.us_invert},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has no downstream invert."},
      :short   => ->(config){"Missing DS Invert"},
      :exp     => ->(config, link, net){!link.ds_invert},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has no shape."},
      :short   => ->(config){"Missing Shape"},
      :exp     => ->(config, link, net){!link.shape},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has no width."},
      :short   => ->(config){"Missing Width"},
      :exp     => ->(config, link, net){!link.conduit_width},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has no height."},
      :short   => ->(config){"Missing Height"},
      :exp     => ->(config, link, net){!link.conduit_height},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has a negative gradient."},
      :short   => ->(config){"-ve gradient"},
      :exp     => ->(config, link, net){link.us_invert < link.ds_invert},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's upstream invert is above ground."},
      :short   => ->(config){"US Invert Above ground"},
      :exp     => ->(config, link, net){link.us_invert > (link.us_node.ground_level || 0)},
    },
    {
      :type    => :error,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's downstream invert is above ground."},
      :short   => ->(config){"DS Invert Above ground"},
      :exp     => ->(config, link, net){link.ds_invert > (link.ds_node.ground_level || 0)},
    },
    {
      :type    => :warn,
      :table   => "_links",
      :message => ->(config){"This pipe has a geospatial duplicate."},
      :short   => ->(config){"Duplication of pipes"},
      :exp     => ->(config, link, net){
        points = link.point_array
        potentialLinks = net.search_at_point((points[0]+points[2])/2,(points[1]+points[3])/2,0.001,"_links")
        potentialLinks.any? {|l| l.point_array == points && link.id != l.id}
      },
    },
    {
      :type    => :warn,
      :table   => "hw_conduit",
      :message => ->(config){"This link's us invert is below the upstream node's chamber floor."},
      :short   => ->(config){"US Invert below chamber floor"},
      :exp     => ->(config, link, net){link.us_invert < link.us_node.chamber_floor},
    },
    {
      :type    => :warn,
      :table   => "hw_conduit",
      :message => ->(config){"This link's ds invert is below the downstream node's chamber floor."},
      :short   => ->(config){"DS Invert below chamber floor"},
      :exp     => ->(config, link, net){link.ds_invert < link.ds_node.chamber_floor},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's width is smaller than the largest upstream pipe. (Constriction)"},
      :short   => ->(config){"Pipe width < largest upstream pipe width"},
      :exp     => ->(config, link, net){
        if link.us_node.us_links.length > 0
          maxWidth = link.us_node.navigate("us_links").map {|l| l.link_type.downcase == "cond" ? l.conduit_width || -Float::INFINITY : -Float::INFINITY}.max
          link.conduit_width < maxWidth
        end
      },
    },
    {
      :type    => :warn,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's crest cover (i.e. ground - invert + conduit_height) is less than #{config.links.complex.minDepthToPipeCrest}m."},
      :short   => ->(config){"< #{config.links.complex.minDepthToPipeCrest}m below ground."},
      :exp     => ->(config, link, net){link.us_node.ground_level - link.us_invert + link.conduit_height < config.links.complex.minDepthToPipeCrest},
    },
    {
      :type    => :warn,
      :table   => "_nodes",
      :message => ->(config){"One or more of the upstream pipe's downstream inverts is lower than one or more of the downstream pipe's upstream inverts. This causes a step-up in the model, which might lead to instability, and is unlikely to simulate reality."},
      :short   => ->(config){"Step up at node"},
      :exp     => ->(config, node, net){
        minUSPipeDSInvert = node.navigate("us_links").select {|l| l.link_type.downcase == "cond"}.map {|l| l.ds_invert || Float::INFINITY}.min
        maxDSPipeUSInvert = node.navigate("ds_links").select {|l| l.link_type.downcase == "cond"}.map {|l| l.us_invert || -Float::INFINITY}.max
        minUSPipeDSInvert < Float::INFINITY & maxDSPipeUSInvert > -Float::INFINITY & minUSPipeDSInvert < maxDSPipeUSInvert
      },
    },
    {#TODO: Implement
      :type    => :warn,
      :table   => "_links",
      :message => ->(config){"The theory of the St Venant equations is stretched when modelling conduits greater than 1:10 gradient."},
      :short   => ->(config){"Conduit gradient > 1:10"},
      :exp     => ->(config, link, net){false},
    },
    {#TODO: Implement
      :type    => :warn,
      :table   => "_links",
      :message => ->(config){"Steep Conduit and High Headloss"},
      :short   => ->(config){"Initilisation Issue - Steep Conduit and High Headloss"},
      :exp     => ->(config, link, net){false},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe is heavily sedimented."},
      :short   => ">#{->(config){config.links.complex.sedimentDepthPercent*100}% sediment applied"},
      :exp     => ->(config, link, net){link.sediment_depth > config.links.complex.sedimentDepthPercent * link.conduit_height},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's sediment depth is greater than the network's defaults."},
      :short   => ->(config){"Sediment Applied"},
      :exp     => ->(config, link, net){link.sediment_depth > net.row_object("hw_conduit_defaults","").sediment_depth},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's width is less than #{config.links.conduit_width.min}mm."},
      :short   => ->(config){"Width < #{config.links.conduit_width.min}"},
      :exp     => ->(config, link, net){link.width < config.links.conduit_width.min},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's width is greater than #{config.links.conduit_width.max}mm."},
      :short   => ->(config){"Width >  #{config.links.conduit_width.max}"},
      :exp     => ->(config, link, net){link.width > config.links.conduit_width.max},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"Gradient < #{config.links.gradient.min}mm. Pipe has no inherent flow rate, and flow is largely inherited from by upstream pipes flow."},
      :short   => ->(config){"This pipe is flat."},
      :exp     => ->(config, link, net){link.gradient < config.links.gradient.min},
    },
    {
      :type    => :info,
      :table   => "_nodes",
      :message => ->(config){"The sum of the downstream pipes sizes is less than #{(config.links.complex.pipeSizeSumFactor*100)}% of the sum of the upstream pipe sizes. Note: This considers only conduits."},
      :short   => ->(config){"Smaller than #{(config.links.complex.pipeSizeSumFactor*100)}% of upstream sum"},
      :exp     => ->(config, node, net){
        usWidthSum = node.navigate("us_links").select {|l| l.link_type.downcase == "cond"}.map {|l| l.conduit_width}.sum
        dsWidthSum = node.navigate("ds_links").select {|l| l.link_type.downcase == "cond"}.map {|l| l.conduit_width}.sum
        dsWidthSum < usWidthSum * config.links.complex.pipeSizeSumFactor
      },
    },
    {
      :type    => :info,
      :table   => "_links",
      :message => ->(config){"This pipe has a kink in it. (UI)"},
      :short   => ->(config){"Pipes has a kink; See vertices."},
      :exp     => ->(config, link, net){link.point_array.length / 2 > 2},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's upstream headloss coefficient is high (> #{config.links.headloss.max})."},
      :short   => ->(config){"High headloss - US"},
      :exp     => ->(config, link, net){link.us_headloss_coeff > config.links.headloss.max},
    },
    {
      :type    => :info,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's downstream headloss coefficient is high (> #{config.links.headloss.max})."},
      :short   => ->(config){"High headloss - DS"},
      :exp     => ->(config, link, net){link.ds_headloss_coeff > config.links.headloss.max},
    },
    {
      :type    => :info,
      :table   => "_links",
      :message => ->(config){"The critical sewer category for this pipe is non blank."},
      :short   => ->(config){"Crticial Sewer"},
      :exp     => ->(config, link, net){link.critical_sewer_category != ""},
    },
    {
      :type    => :info,
      :table   => "_links",
      :message => ->(config){"The pipe's shape is classified as 'UTOP'. Should this be 'Unknown'?"},
      :short   => ->(config){"Culverted Water Course"},
      :exp     => ->(config, link, net){link.shape.downcase == "utop"},
    },
    {
      :type    => :error,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment's id is not defined."},
      :short   => ->(config){"Missing Subcatchment ID"},
      :exp     => ->(config, subc, net){!subc.id},
    },
    {
      :type    => :error,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment does not drain to a node."},
      :short   => ->(config){"SC Node not assigned"},
      :exp     => ->(config, subc, net){!subc.node_id},
    },
    {
      :type    => :error,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment drains to an node that doesn't exist."},
      :short   => ->(config){"SC Node does not exist exist"},
      :exp     => ->(config, subc, net){!net.row_object("_nodes",subc.node_id)},
    },
    {
      :type    => :error,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment is foul/combined but population is 0 or undefined."},
      :short   => ->(config){"Foul SC without population"},
      :exp     => ->(config, subc, net){["foul","combined","sanitary"].include?(sc.system_type.downcase) & (subc.population||0) == 0},
    },
    {
      :type    => :error,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment is storm but contributing area is 0 or undefined."},
      :short   => ->(config){"Storm SC without cont area"},
      :exp     => ->(config, subc, net){["storm","overland"].include(sc.system_type.downcase) & (subc.contributing_area||0) == 0},
    },
    {
      :type    => :error,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment has trade flow but does not have a trade profile."},
      :short   => ->(config){"Trade profile Missing"},
      :exp     => ->(config, subc, net){subc.trade_flow > 0 && (trade_profile ||0 ) == 0},
    },
    {
      :type    => :warn,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment: sum(areas) > contributing area"},
      :short   => ->(config){"Contributing Area > Sum of Runoff Area"},
      :exp     => ->(config, subc, net){Range.new(1,12).to_a.map {|e| subc["area_absolute_#{e}"]||0}.sum > subc.contributing_area},
    },
    {
      :type    => :warn,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment total area is not defined."},
      :short   => ->(config){"Total Area is blank"},
      :exp     => ->(config, subc, net){!subc.total_area},
    },
    {
      :type    => :warn,
      :table   => "hw_subcatchment",
      :message => ->(config){"Area Flag"},
      :short   => ->(config){"Total Area Flag is not #D"},
      :exp     => ->(config, subc, net){(subc.total_area_flag||"") != config.general.flags.default},
    },
    {
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment has additional foul flow"},
      :short   => ->(config){"Additional Foul Flow Applied"},
      :exp     => ->(config, subc, net){(subc.additional_foul_flow||0) > 0},
    },
    {
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment has base flow"},
      :short   => ->(config){"Base flow applied"},
      :exp     => ->(config, subc, net){(subc.base_flow||0) > 0 },
    },
    {
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment has trade flow"},
      :short   => ->(config){"trade flow applied"},
      :exp     => ->(config, subc, net){(subc.trade_flow||0) > 0},
    },
    {
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment has a slow response."},
      :short   => ->(config){"Slow Response applied"},
      :exp     => ->(config, subc, net){subc.ground_id!=""},
    },
    {
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment drains to a node outside it's bounds."},
      :short   => ->(config){"Drain to an outside Node"},
      :exp     => ->(config, subc, net){
        drain = net.row_object("_nodes",subc.node_id)
        subcatchments = net.search_at_point(drain.x,drain.y,0,"hw_subcatchment")
        !subcatchments.any? {|sc| sc.id == subc.id}
      },
    },
    {
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment drains to an outfall."},
      :short   => ->(config){"Drain to an outfall"},
      :exp     => ->(config, subc, net){net.row_object("_nodes",subc.node_id).node_type.downcase == "outfall"},
    },
    {
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"This subcatchment drains to a break node."},
      :short   => ->(config){"Drain to break node"},
      :exp     => ->(config, subc, net){net.row_object("_nodes",subc.node_id).node_type.downcase == "break"},
    },
    {#TODO: Configure based on cross sectional area / ground levels?
    #TODO: Nodes within.ground_level.max - Nodes within.ground_level.min > catchment_slope ?
      :type    => :info,
      :table   => "hw_subcatchment",
      :message => ->(config){"Unrealistic catchment_slope found for subcatchment."},
      :short   => ->(config){"Catchment Slope > #{config.subcatchment.catchmentSlope.max}"},
      :exp     => ->(config, subc, net){subc.catchment_slope > config.subcatchment.catchmentSlope.max},
    },
    {
      :type    => :error,
      :table   => "hw_pump",
      :message => ->(config){"Pump discharge rate is not defined."},
      :short   => ->(config){"Missing Discharge"},
      :exp     => ->(config, pump, net){["fixpmp","vspmp"].include?(pump.link_type) & !pump.discharge},
    },
    {
      :type    => :error,
      :table   => "hw_pump",
      :message => ->(config){"Pump switch on level is not defined."},
      :short   => ->(config){"Missing ON Level"},
      :exp     => ->(config, pump, net){!pump.switch_on_level},
    },
    {
      :type    => :error,
      :table   => "hw_pump",
      :message => ->(config){"Pump switch off level is not defined."},
      :short   => ->(config){"Missing OFF Level"},
      :exp     => ->(config, pump, net){!pump.switch_off_level},
    },
    {
      :type    => :error,
      :table   => "hw_pump",
      :message => ->(config){"Pump on level is below off level."},
      :short   => ->(config){"On level <= Off Level"},
      :exp     => ->(config, pump, net){pump.switch_on_level <= pump.switch_off_level},
    },
    {
      :type    => :info,
      :table   => "hw_pump",
      :message => ->(config){"Max and Min Pump Flow"},
      :short   => ->(config){"Max Pump Flow is X and Min Y"},
      :exp     => ->(config, pump, net){false},
    },
    {
      :type    => :warn,
      :table   => "hw_pump",
      :message => ->(config){"Dicharge Rate < 8 l/s while assumed flag supplied"},
      :short   => ->(config){"Pump has a low assumed flow rate."},
      :exp     => ->(config, pump, net){["fixpmp","vspmp"].include?(pump.link_type) & pump.discharge < config.pump.discharge.min && pump.discharge_flag == config.general.flags.assumed},
    },
    {
      :type    => :info,
      :table   => "hw_pump",
      :message => ->(config){"Pump has a high flow rate."},
      :short   => ->(config){"Dicharge Rate > 30 l/s"},
      :exp     => ->(config, pump, net){["fixpmp","vspmp"].include?(pump.link_type) & pump.discharge > config.pump.discharge.max},
    },
    {
      :type    => :error,
      :table   => "hw_orifice",
      :message => ->(config){"Orifice invert level is not defined."},
      :short   => ->(config){"Missing Invert"},
      :exp     => ->(config, link, net){!link.invert},
    },
    {
      :type    => :error,
      :table   => "hw_orifice",
      :message => ->(config){"Orifice diameter is not defined."},
      :short   => ->(config){"Missing Dia"},
      :exp     => ->(config, link, net){!link.diameter},
    },
    {
      :type    => :error,
      :table   => "hw_orifice",
      :message => ->(config){"Orifice diameter is 0m."},
      :short   => ->(config){"Dia = 0mm"},
      :exp     => ->(config, link, net){link.diameter == 0},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Limiting Discharge Applied"},
      :short   => ->(config){"Limiting Discharge Applied"},
      :exp     => ->(config, link, net){link.limiting_discharge > 0},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Orifice limiting discharge is lower than the minimum specified #{config.orifice.limitingDischarge.min} lps."},
      :short   => ->(config){"Limiting Discharge < #{config.orifice.limitingDischarge.min}"},
      :exp     => ->(config, link, net){link.limiting_discharge < config.orifice.limitingDischarge.min},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Orifice diameter smaller than the minimum specified #{config.orifice.diameter.min} m."},
      :short   => ->(config){"Dia < #{config.orifice.diameter.min}"},
      :exp     => ->(config, link, net){link.diameter < config.orifice.diameter.min},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Orifice diameter larger than the maximum specified #{config.orifice.diameter.max} m."},
      :short   => ->(config){"Dia > #{config.orifice.diameter.max} m"},
      :exp     => ->(config, link, net){link.diameter > config.orifice.diameter.max},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Discharge coefficient is default."},
      :short   => ->(config){"Discharge coefficient is default."},
      :exp     => ->(config, link, net){["orific","vldorf"].include?(link.link_type) & link.discharge_coeff_flag.downcase == config.general.flags.default},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Discharge coefficient is less than the minimum (#{config.orifice.dischargeCoeff.min})."},
      :short   => ->(config){"Discharge coefficient < #{config.orifice.dischargeCoeff.min}"},
      :exp     => ->(config, link, net){["orific","vldorf"].include?(link.link_type) & link.discharge_coeff < config.orifice.dischargeCoeff.min},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Discharge coefficient is greater than the maximum (#{config.orifice.dischargeCoeff.max})."},
      :short   => ->(config){"Discharge coefficient > #{config.orifice.dischargeCoeff.max}"},
      :exp     => ->(config, link, net){["orific","vldorf"].include?(link.link_type) & link.discharge_coeff > config.orifice.dischargeCoeff.max},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Secondary discharge coefficient is default."},
      :short   => ->(config){"Secondary discharge coefficient is default."},
      :exp     => ->(config, link, net){["orific","vldorf"].include?(link.link_type) & link.secondary_discharge_coeff_flag.downcase == config.general.flags.default},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Secondary discharge coefficient is less than the minimum (#{config.orifice.dischargeCoeff.min})."},
      :short   => ->(config){"Secondary discharge coefficient < #{config.orifice.dischargeCoeff.min}"},
      :exp     => ->(config, link, net){["orific","vldorf"].include?(link.link_type) & link.secondary_discharge_coeff < config.orifice.dischargeCoeff.min},
    },
    {
      :type    => :info,
      :table   => "hw_orifice",
      :message => ->(config){"Secondary discharge coefficient is greater than the maximum (#{config.orifice.dischargeCoeff.max})."},
      :short   => ->(config){"Secondary discharge coefficient > #{config.orifice.dischargeCoeff.max}"},
      :exp     => ->(config, link, net){["orific","vldorf"].include?(link.link_type) & link.secondary_discharge_coeff > config.orifice.dischargeCoeff.max},
    },
    {
      :type    => :error,
      :table   => "hw_weir",
      :message => ->(config){"Weir crest missing"},
      :short   => ->(config){"Missing crest"},
      :exp     => ->(config, link, net){!link.crest},
    },
    {
      :type    => :error,
      :table   => "hw_weir",
      :message => ->(config){"Weir width missing"},
      :short   => ->(config){"Missing width"},
      :exp     => ->(config, link, net){!link.width},
    },
    {#TODO:
      :type    => :warn,
      :table   => "hw_weir",
      :message => ->(config){"broad crested weirs that are not broad (<1.5m)"},
      :short   => ->(config){"Initilisation Issue"},
      :exp     => ->(config, link, net){false},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Weir crest less than minimum in spec"},
      :short   => ->(config){"Crest < #{config.weir.crest.min}"},
      :exp     => ->(config, link, net){link.crest < config.weir.crest.min},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Weir crest greater than maximum in spec"},
      :short   => ->(config){"Crest > #{config.weir.crest.max}"},
      :exp     => ->(config, link, net){link.crest > config.weir.crest.max},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Weir width less than minimum in spec"},
      :short   => ->(config){"Width < #{config.weir.width.min}"},
      :exp     => ->(config, link, net){link.width < config.weir.width.min},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Weir width greater than maximum in spec"},
      :short   => ->(config){"Width > #{config.weir.width.max}"},
      :exp     => ->(config, link, net){link.width > config.weir.width.max},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Discharge coefficient is default."},
      :short   => ->(config){"Discharge coefficient is default."},
      :exp     => ->(config, link, net){["weir","vwweir","vcweir"].include(link.link_type) & link.discharge_coeff_flag.downcase == config.general.flags.default},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Discharge coefficient is less than the minimum (#{config.weir.dischargeCoeff.min})."},
      :short   => ->(config){"Discharge coefficient < #{config.weir.dischargeCoeff.min}"},
      :exp     => ->(config, link, net){["weir","vwweir","vcweir"].include(link.link_type) & link.discharge_coeff < config.weir.dischargeCoeff.min},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Discharge coefficient is greater than the maximum (#{config.weir.dischargeCoeff.max})."},
      :short   => ->(config){"Discharge coefficient > #{config.weir.dischargeCoeff.max}"},
      :exp     => ->(config, link, net){["weir","vwweir","vcweir"].include(link.link_type) & link.discharge_coeff > config.weir.dischargeCoeff.max},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Secondary discharge coefficient is default."},
      :short   => ->(config){"Secondary discharge coefficient is default."},
      :exp     => ->(config, link, net){["weir","vwweir","vcweir"].include(link.link_type) & link.secondary_discharge_coeff_flag.downcase == config.general.flags.default},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Secondary discharge coefficient is less than the minimum (#{config.weir.dischargeCoeff.min})."},
      :short   => ->(config){"Secondary discharge coefficient < #{config.weir.dischargeCoeff.min}"},
      :exp     => ->(config, link, net){["weir","vwweir","vcweir"].include(link.link_type) & link.secondary_discharge_coeff < config.weir.dischargeCoeff.min},
    },
    {
      :type    => :info,
      :table   => "hw_weir",
      :message => ->(config){"Secondary discharge coefficient is greater than the maximum (#{config.weir.dischargeCoeff.max})."},
      :short   => ->(config){"Secondary discharge coefficient > #{config.weir.dischargeCoeff.max}"},
      :exp     => ->(config, link, net){["weir","vwweir","vcweir"].include(link.link_type) & link.secondary_discharge_coeff > config.weir.dischargeCoeff.max},
    },
    {#TODO: Implement
      :type    => :warn,
      :table   => "_nodes",
      :message => ->(config){"Combined Nodes on a manmade surface should normally be of flood_type stored. (indicating that all flood water at any of the unsealed manholes returns to the drainage system after the levels in the system have subsided.)"},
      :short   => ->(config){"Stored nodes on manmade surfaces"},
      :exp     => ->(config, node, net){false},
    },
  ]
end





