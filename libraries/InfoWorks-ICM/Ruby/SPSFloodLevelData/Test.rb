require_relative 'SPSFloodLevels.rb'
require 'json'

#Get path to write data to
path = WSApplication.file_dialog(false, "json", "Save SPS Flood Levels data...", WSApplication.current_network.model_object.name + "_SpsFloodAnalysis", false, true)

#Get sps flood levels data
reportData = getSPSFloodLevelData(WSApplication.current_network)

#Write as JSON to file
File.write(path, JSON.pretty_generate(reportData))
