#LinkWalker
#  Walk procedurally up or down stream.
#  Can be used to build cellular automata.
#
#Directions:
# us
# ds
# us*
# ds*
# *
class LinkWalker
  require 'OStruct'
  attr_accessor :latest, :links, :direction, :meta, :start
  def initialize(latestLink,links,direction,startLink=nil)
    @latest = latestLink
    @links = links
    @direction = direction
    @meta = OpenStruct.new
    
    #Track startLinks
    if startLink==nil
      @start = latestLink
    else
      @start = startLink
    end
  end
  def allLinks()
    return @links + [@latest]
  end
  def next()
    if ["us","ds"].include?(@direction)
      next_node = @latest.navigate(@direction + "_node")[0]
      
      if next_node
        next_links = next_node.navigate(@direction + "_links")
        next_links = next_links.select {|nl| !(self.allLinks.map{|l| l.id}.include?(nl.id))}
        
        return next_links.map do |link|
          next LinkWalker.new(link,@links + [@latest],@direction,@start)
        end
      else
        return []
      end
    elsif @direction == "*"
      us_links = @latest.us_node ? @latest.us_node.navigate("us_links") : []
      ds_links = @latest.ds_node ? @latest.ds_node.navigate("ds_links") : []
      links = us_links + ds_links
      links = links.select do |l|
        @links.index {|t| t.id == l.id} == nil
      end
      return links.map do |link|
        next LinkWalker.new(link,@links + [@latest],@direction,@start)
      end
    end
  end
end
  
  
#Trace a link or node up or downstream until some condition is met.  
#param element: WSNode | WSLink - Element to start trace from
#param direction: "us" | "ds" | "*"
#param block: block to be called on each link.  If the block returns true then the walker will stop.
#return: array of LinkWalkers
def traceTil(element,direction,&block)
  walkers = []
  if element.class == WSNode
    if direction == "us"
      nextLinks = element.us_links
    else
      nextLinks = element.ds_links
    end
  elsif element.class == WSLink
    nextLinks = [element]
  end
  
  #Create a walker for each link
  nextLinks.each do |link|
    #Create a single walker
    lw = LinkWalker.new(link,[],direction)
    lw.meta.alive = true
    
    #Like in a cellular automata, run continuously until no cells are alive anymore.
    walkers.push(lw)
    while walkers.detect {|w| w.meta.alive}
      #Only process living walkers
      alive = walkers.select {|w| w.meta.alive}
      alive.each do |walker|
        #Automatically kill all walkers
        walker.meta.alive = false
        
        #if the block succeeds then set flag to true and stop walking,
        #otherwise continue walking and ensure the next generation are also living.
        if block.call(walker.latest,walker)
          walker.meta.flag = true
        else
          nextWalkers = walker.next()
          nextWalkers.each {|w| w.meta.alive = true}
          walkers += nextWalkers
        end
      end
    end
  end
  
  #Return walkers which have matched the flag
  return walkers.select {|w| w.meta.flag}
end