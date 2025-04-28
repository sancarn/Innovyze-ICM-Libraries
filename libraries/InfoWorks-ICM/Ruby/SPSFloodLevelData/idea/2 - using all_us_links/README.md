# Test 2

I figured using `all_us_links` might perform better than walking the graph procedurally, with repeated calls to the ruby engine. This way all upstream links can be obtained in one go from the C engine.

## Original mechanism

* Find all sps
    * Iterate through them
        * iteratively trace upstream using `WSModelWalker` until a pumping station is reached.

## New mechanism

* Find all SPS
    * Find all_us_links for all SPS
        * sort by number of links in each network
            * prune out unnecessary links from larger networks



