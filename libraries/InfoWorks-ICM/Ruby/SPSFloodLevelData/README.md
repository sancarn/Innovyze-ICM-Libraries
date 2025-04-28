# SPS Flood Level detection

This script identifies pumping stations (SPS) and calculates their flood levels based on upstream manholes, sps chamber data and combined sewer overflow (CSO) spill level data. It is designed for use with sewer network models in InfoWorks ICM.

## Overview

The flood level for each SPS is determined by finding the lowest level among:

* The flood level of the pumping station chamber itself.
* The flood levels of upstream manholes (excluding sealed manholes).
* The spill levels of any connected CSO structures.
    * CSOs are found by checking for upstream bifurcations and then verifying divergence in reachable outfalls

The upstream subnetwork is found (i.e. not tracing through other SPS), to ensure only the relevant hydraulically connected spill level is reached.

### Weaknesses

* This model assumes a fixed static planar head, which isn't the case in reality. For a better approximation a 1D simulation must be run (I believe?).
* Invert for spills is assumed as the invert within the spill link itself, not the maximum invert following the spill location. Better approximations may continue to check the gradient downstream until a maximum invert is reached.


## Exposed Functions

`getSPSFloodLevelData` - Core methodto return SPS data with flood level information.
`getOutfalls` - Helper. Returns all outfalls downstream of a given link
`getManholeFloodLevel` - Helper. Calculates the flood level for a manhole
`getSpillLevel` - Helper. Assuming a given spill link, this method will return the spill level for this link.
`subnetworks` - Helper. Obtain the network upstream of a given link, enclosed by upstream pumping stations.

## Sample usage

```rb
require_relative 'SPSFloodLevels.rb'
require 'json'

#Get path to write data to
path = WSApplication.file_dialog(false, "json", "Save SPS Flood Levels data...", WSApplication.current_network.model_object.name + "_SpsFloodAnalysis", false, true)

#Get sps flood levels data
reportData = getSPSFloodLevelData(WSApplication.current_network)

#Write as JSON to file
File.write(path, JSON.pretty_generate(reportData))
```