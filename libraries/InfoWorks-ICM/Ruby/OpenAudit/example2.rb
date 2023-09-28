module SevernTrent
  Config = {
    :specSevernTrent => {
      :nodes => {
        :complex => {
          :lostElevationDistance => 15,
          :lostElevationThreshold => 15,
          :ifStored => {
            :floodable_area => 0.2,
            :flood_depth_1 => 0.1,
            :flood_area_1 => 0.1, #10%
            :flood_depth_2 => 0.3,
            :flood_area_2 => 1, #100%
          }
        }
      },
      :links => {
        :roughness => {
          :bot => {
            :min => 1.5, 
            :max => 3
          },
          :top => {
            :min => 0.1, 
            :max => 50
          },
          :ranges => {
            "VC"  => {"min" =>1    , "max" =>3}  ,
            "CO"  => {"min" =>0.6  , "max" =>6}  ,
            "CI"  => {"min" =>0.15 , "max" =>10} ,
            "GRP" => {"min" =>0.1  , "max" =>1}  ,
            "PVC" => {"min" =>0.3  , "max" =>1.5},
            "BR"  => {"min" =>3    , "max" =>50} ,
            "UNKN"=> {"min" =>1.5  , "max" =>3}
          },
          :type => "CW"
        }
      }
    }
  }
  
  RuleTypes = {
    :SevernTrent => {
      :color => "rgb(47, 78, 51)",
      :font_color => "#ffffff",
      :icon => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-6.75 -4.753075 58.5 28.51845"><path d="M45 19.0122H0V0h45z" fill="#fff"/><path d="M.7906.9h43.4199v8.2634H.7905z" fill="#23346a"/><path d="M.7906 9.953h43.4199v8.2634H.7905z" fill="#009340"/><path d="M8.6774 7.0347H7.209c-.7542 0-1.5247-.126-1.5247-1.0608v-.3587h.642v.3481c0 .3126.1295.4936.7907.4936h1.641c.7818 0 .9208-.1704.9208-.6502 0-.4138-.1076-.5426-.7803-.5426h-1.004c-1.6087 0-2.2162-.1037-2.2162-1.2065 0-.973.6206-1.163 1.6927-1.163h1.1387c1.2496 0 1.7142.299 1.7142 1.1034v.2082h-.641l-.0014-.0716c-.0095-.5486-.0117-.6625-1.39-.6625h-.5612c-1.0443 0-1.3092.061-1.3092.6233 0 .3976.0773.5482.8989.5482h1.5652c1.0623 0 1.5357.3186 1.5357 1.0337v.2536c0 1.1039-1.0287 1.1039-1.6436 1.1039m6.9975-.0433h-4.0054V2.9377h3.9838v.5775h-3.309v1.101h3.1796v.5779h-3.1796v1.2196h3.3306v.5048zm4.0069 0h-.7338l-.0208-.0377-2.1647-3.9077-.06-.1083h.761l.0208.0377 1.8306 3.3172 1.8309-3.3172.0208-.0377h.7606l-.0596.1083-2.165 3.9077zm7.4037 0H23.08v-4.054h3.9835v.5776H23.755v1.101h3.1792v.5776H23.755v1.2199h3.3305v.5048zm5.7971 0h-.6428v-.931c0-.5273-.2074-.6127-.7045-.6127H29.028v1.5437h-.6748v-4.054h3.1982c1.166 0 1.3794.3975 1.3794 1.1797v.3185c0 .4819-.2367.6756-.495.7574.3066.1267.4467.3588.4467.7267v.9988zM29.028 4.87h2.4642c.636 0 .7637-.189.7637-.4935v-.3563c0-.3433-.0882-.5048-.8932-.5048H29.028zm10.2946 2.1214h-.8901l-.0212-.0201-3.4558-3.315v3.3351h-.6745V2.9376h.8901l.0212.02 3.4554 3.3151V2.9376h.6749v3.9811zM11.253 16.0448h-.6748v-3.4762H8.6027v-.5776h4.6263v.5776h-1.976v3.4032zm7.68 0h-.6421v-.931c0-.5277-.2082-.613-.7045-.613h-2.5072v1.544h-.6749v-4.0537h3.1983c1.166 0 1.379.3972 1.379 1.1793v.3186c0 .4818-.2364.6759-.4953.7577.3066.1263.4466.3584.4466.7264v.9987zm-3.8538-2.1212h2.4641c.6357 0 .7638-.1891.7638-.4939v-.3567c0-.3425-.0886-.5044-.8936-.5044h-2.3343zm9.273 2.1212H20.347V11.991h3.9835v.5776h-3.309v1.101h3.1795v.5778h-3.1795v1.2196h3.3307v.5048zm6.3098.0002h-.89l-.0215-.0205-3.4555-3.3147v3.3352h-.6745v-4.0542h.8901l.0212.0205 3.4554 3.315V11.991h.6749v3.9814zm3.8311-.0002h-.6748v-3.4762h-1.976v-.5778h4.6264v.5778H34.493v3.4032z" fill="#fff"/></svg>'
    }
  }

  Rules = [
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"This manhole has an invalid node name."},
      :short   => ->(config){"Node name does not conform SevernTrent Spec"},
      :exp     => ->(config, node, net){!(/[A-Z]{2}\d{8}(_\w+)?/i =~ node.id)},
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"This pipe has a malformed link suffix."},
      :short   => ->(config){"Link Suffix not as per SevernTrent Spec"},
      :exp     => ->(config, node, net){
        spec = Range.new(1,node.ds_links.length).to_a
        actual = node.navigate("ds_links").map(|l| l.link_suffix.to_i)
        (spec-actual).length > 0 || (actual-spec).length > 0 
      },
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's bottom roughness is less than the minimum applicable bottom roughness. (< #{config.specSevernTrent.links.roughness.bot.min}mm)"},
      :short   => ->(config){"bottom roughness < #{config.specSevernTrent.links.roughness.bot.min}"},
      :exp     => ->(config, link, net){["foul","combined"].include?(link.system_type.downcase) & link.bottom_roughness_CW < config.specSevernTrent.links.roughness.bot.min},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's bottom roughness is greater than the maximum applicable bottom roughness. (> #{config.specSevernTrent.links.roughness.bot.max}mm)"},
      :short   => ->(config){"bottom roughness > #{config.specSevernTrent.links.roughness.bot.max}"},
      :exp     => ->(config, link, net){["foul","combined"].include?(link.system_type.downcase) & link.bottom_roughness_CW > config.specSevernTrent.links.roughness.bot.max},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's top roughness is less than the minimum applicable top roughness. (< #{config.specSevernTrent.links.roughness.top.min}mm)"},
      :short   => ->(config){"top roughness < #{config.specSevernTrent.links.roughness.top.min}"},
      :exp     => ->(config, link, net){["foul","combined"].include?(link.system_type.downcase) & link.top_roughness_CW < config.specSevernTrent.links.roughness.top.min},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe's top roughness is greater than the maximum applicable top roughness. (> #{config.specSevernTrent.links.roughness.top.max}mm)"},
      :short   => ->(config){"top roughness > #{config.specSevernTrent.links.roughness.top.max}"},
      :exp     => ->(config, link, net){["foul","combined"].include?(link.system_type.downcase) & link.top_roughness_CW > config.specSevernTrent.links.roughness.top.max},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has an invalid material."},
      :short   => ->(config){"non Standard Material"},
      :exp     => ->(config, link, net){!config.specSevernTrent.links.roughness.ranges.key?(link.conduit_material)},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_conduit",
      :message => ->(config){"This pipe has an unknown material."},
      :short   => ->(config){"Material Unknown"},
      :exp     => ->(config, link, net){link.conduit_material == "UNKN"},
    },
    {
      :type    => :SevernTrent,
      :table   => "_links",
      :message => ->(config){"The pipe's top roughness is greater than the maximum for this material."},
      :short   => ->(config){"Roughness above SevernTrent range"},
      :exp     => ->(config, node, net){link.top_roughness_CW > config.specSevernTrent.links.roughness.ranges[link.conduit_material].max},
    },
    {
      :type    => :SevernTrent,
      :table   => "_links",
      :message => ->(config){"The pipe's top roughness is less than the minimum for this material."},
      :short   => ->(config){"Roughness below SevernTrent range"},
      :exp     => ->(config, node, net){link.top_roughness_CW < config.specSevernTrent.links.roughness.ranges[link.conduit_material].min},
    },
    {
      :type    => :SevernTrent,
      :table   => "_links",
      :message => ->(config){"This pipe's roughness type is not 'Colebrook-White'."},
      :short   => ->(config){"Roughness type Not CW"},
      :exp     => ->(config, node, net){link.roughness_type != config.specSevernTrent.links.roughness.type},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_subcatchment",
      :message => ->(config){"WRAP soil type is not 4."},
      :short   => ->(config){"WRAP Type not 4"},
      :exp     => ->(config, node, net){subc.soil_class != SubcatchmentSoilClass},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment total area is larger than spec dictates."},
      :short   => ->(config){"SC Area > #{SubcatchmentMaximumArea}"},
      :exp     => ->(config, node, net){subc.total_area > SubcatchmentMaximumArea},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment total area is smaller than spec dictates."},
      :short   => ->(config){"SC Area < #{SubcatchmentMinimumArea}"},
      :exp     => ->(config, node, net){subc.total_area < SubcatchmentMinimumArea},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment id should equal to draining node id."},
      :short   => ->(config){"SC ID and Node mismatch"},
      :exp     => ->(config, node, net){subc.id == subc.node_id & net.row_object("hw_subcatchment",subc.node_id) == nil},
    },
    {
      :type    => :SevernTrent,
      :table   => "hw_subcatchment",
      :message => ->(config){"Subcatchment ID is non standard."},
      :short   => ->(config){"Non SevernTrent SC ID"},
      :exp     => ->(config, node, net){/[A-Z]{2}\d{8}(_\w+)?[A-Za-z]?/i =~ subc.id},
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257: Foul manholes within storm subcatchments should have either flood_type of 'lost' (indicating that all floodwater is lost from the combined/foul drainage system into the storm system.) or 'sealed' (indicating that manhole cannot flood)"},
      :short   => ->(config){"Foul manholes in storm subcatchments should have 'lost' flood type"},
      :exp     => ->(config, node, net){
        if ["foul","combined"].indclude?(node.system_type.downcase)
          catchmentsWithin = net.search_at_point(node.x,node.y,0,"hw_subcatchment") || []
          if catchmentsWithin.any?(){|sc| sc.system_type == "storm"}
            !["lost","sealed"].include?(node.flood_type.downcase)
          end
        end
      },
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257: If system_type = 'combined' then flood_type generally set to 'stored' (indicating that all flood water at any of the unsealed manholes returns to the drainage system after the levels in the system have subsided.)"},
      :short   => ->(config){""},
      :exp     => ->(config, node, net){
        if ["foul","combined"].indclude?(node.system_type.downcase)
          catchmentsWithin = net.search_at_point(node.x,node.y,0,"hw_subcatchment") || []
          if !catchmentsWithin.any?(){|sc| sc.system_type == "storm"}
            !["stored","sealed"].include?(node.flood_type.downcase)
          end
        end
      },
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257: If system_type = 'combined' and Lidar shows water will be lost then flood_type = 'lost'"},
      :short   => ->(config){"Manholes on steep ground level gradients should have flood type of lost"},
      :exp     => ->(config, node, net){
        if ["foul","combined"].indclude?(node.system_type.downcase)
          nodesNearby = net.search_at_point(node.x, node.y, 30, "_nodes")
          if nodesNearby.any?(){|n| node.ground_level - n.ground_level > config.specSevernTrent.nodes.complex.lostElevationThreshold}
            !["lost","sealed"].include?(node.flood_type.downcase)
          end
        end
      },
    },
    {#TODO: How to identify dummy manholes?
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257: Dummy manholes used for modelling, e.g. modelling of ancillaries and pipe junctions, flood_type = 'sealed'"},
      :short   => ->(config){""},
      :exp     => ->(config, node, net){false},
    },
    {#TODO: if node type stored then ...?
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257: If node_type = 'stored' then:"},
      :short   => ->(config){""},
      :exp     => ->(config, node, net){false},
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257 claims that when node_type=='stored' floodable_area should equal 0.2m"},
      :short   => ->(config){"Stored manhole with floodable_area != 0.2m"},
      :exp     => ->(config, node, net){node.flood_type.downcase == "stored" & node.floodable_area != config.specSevernTrent.nodes.complex.ifStored.floodable_area}
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257 claims that when node_type=='stored' flood_depth_1 should equal 0.1m"},
      :short   => ->(config){"Stored manhole with flood_depth_1 != 0.1m"},
      :exp     => ->(config, node, net){node.flood_type.downcase == "stored" & node.flood_depth_1 != config.specSevernTrent.nodes.complex.ifStored.flood_depth_1},
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257 claims that when node_type=='stored' flood_area_1 should equal 10%"},
      :short   => ->(config){"Stored manhole with flood_area_1 != 10%"},
      :exp     => ->(config, node, net){node.flood_type.downcase == "stored" & node.flood_area_1 != config.specSevernTrent.nodes.complex.ifStored.flood_area_1},
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257 claims that when node_type=='stored' flood_depth_2 should equal 0.3m"},
      :short   => ->(config){"Stored manhole with flood_depth_2 != 0.3m"},
      :exp     => ->(config, node, net){node.flood_type.downcase == "stored" & node.flood_depth_2 != config.specSevernTrent.nodes.complex.ifStored.flood_depth_2},
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"STSMPProc257 claims that when node_type=='stored' flood_area_2 should equal 100%"},
      :short   => ->(config){"Stored manhole with flood_area_2 != 100%"},
      :exp     => ->(config, node, net){node.flood_type.downcase == "stored" & node.flood_area_2 != config.specSevernTrent.nodes.complex.ifStored.flood_area_2},
    },
    {#TODO: How to identify within garden/field
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"If node in garden/field flood_type = 'lost' (requires GIS)"},
      :short   => ->(config){""},
      :exp     => ->(config, node, net){false},
    },
    {#TODO: How to identify on road/highway
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"If node on road flood_type should be 'stored'"},
      :short   => ->(config){""},
      :exp     => ->(config, node, net){false},
    },
    {
      :type    => :SevernTrent,
      :table   => "_nodes",
      :message => ->(config){"If system_type=='storm' and in storm subcatchment then flood_type == 'stored'"},
      :short   => ->(config){"Storm nodes in storm subcatchments should store water"},
      :exp     => ->(config, node, net){
        if ["storm"].indclude?(node.system_type.downcase)
          catchmentsWithin = net.search_at_point(node.x,node.y,0,"hw_subcatchment") || []
          if catchmentsWithin.any?(){|sc| sc.system_type == "storm"}
            !["stored","sealed"].include?(node.flood_type.downcase)
          end
        end
      },
    }
  ]
end

require 'OpenAudit.rb'
require 'pp'

engine = OpenAudit::Engine.new(SevernTrent::Rules, SevernTrent::RuleTypes, SevernTrent::Config)
audit = engine.run()
pp audit[:results]
path = WSApplication.file_dialog(false, "json", "JSON audit results", "#{Date.today.to_s}-audit-results", false, true)
File.write(path, audit.to_json)
