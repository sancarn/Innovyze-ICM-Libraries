require 'ostruct'
module WSModelWalker
  #This is a generic class which can be used to walk through any object.
  class ObjectWalker
    attr_reader :current, :path, :start
    attr_accessor :expand_fn, :alive, :matched, :meta
    
    # Initialize the walker with the current object, path, start object, and expansion function
    # @param current - The current object being walked
    # @param path - The path taken to reach the current object (default: empty array)
    # @param start - The starting object (default: current object)
    # @param expand_fn - A function to expand the current object into its next nodes (default: nil)
    # @return - A new ObjectWalker instance
    def initialize(current, path: [], start: nil, expand_fn: nil)
      @current = current
      @path = path
      @start = start || current
      @expand_fn = expand_fn
      @alive = true
      @matched = false
      @meta = OpenStruct.new
    end
    
    # Get all nodes in the path taken to reach the current object
    # @return - An array of all nodes in the path
    def all_nodes
      @path + [@current]
    end

    # Get the next walkers based on the current object and the expansion function
    # @param custom_expand_fn as ->(current: any, walker: ObjectWalker): any[] - An custom override for the expansion function (default: nil)
    # @return - An array of new ObjectWalker instances for the next nodes
    # @raise - Raises an error if no expansion function is provided at initialization or during call.
    # @note - The custom expansion function should take the current object and the walker instance as arguments
    #         and return an array of next nodes.
    def next_walkers(custom_expand_fn = nil)
      fn = custom_expand_fn || @expand_fn
      raise "No expand function provided" unless fn

      next_nodes = Array(fn.call(@current, self))
      return [] unless next_nodes

      seen = all_nodes.map(&:object_id)

      next_nodes.reject { |n| seen.include?(n.object_id) }
                .map { |n| ObjectWalker.new(n, path: all_nodes, start: @start, expand_fn: @expand_fn) }
    end
  end
  
  def traceTil(start_objs, expand_fn:, match_fn:)
    open_walkers = Array(start_objs).map do |obj|
      ObjectWalker.new(obj, expand_fn: expand_fn)
    end

    while open_walkers.any?(&:alive)
      open_walkers.select(&:alive).each do |walker|
        walker.alive = false

        if match_fn.call(walker.current, walker)
          walker.matched = true
        else
          walker.next_walkers.each do |next_walker|
            next_walker.alive = true
            open_walkers << next_walker
          end
        end
      end
    end
    open_walkers.select(&:matched)
  end

  #Downstream trace til a condition is met
  #@param start - The starting object for the trace
  #@param block as ->(current: any, walker: ObjectWalker): boolean - A condition to check against the current object. Returning true will stop the trace.
  #@return - An array of walkers that matched the condition in the block
  def icmTraceTilDS(start, &block)
    expand_fn = ->(link, walker) {
      next_node = link.ds_node
      next_node ? next_node.navigate("ds_links") : []
    }
    traceTil(start, expand_fn: expand_fn, match_fn: block)
  end

  #Upstream trace til a condition is met
  #@param start - The starting object for the trace
  #@param block as ->(current: any, walker: ObjectWalker): boolean - A condition to check against the current object. Returning true will stop the trace.
  #@return - An array of walkers that matched the condition in the block
  def icmTraceTilUS(start, &block)
    expand_fn = ->(link, walker) {
      next_node = link.us_node
      next_node ? next_node.navigate("us_links") : []
    }
    traceTil(start, expand_fn: expand_fn, match_fn: block)
  end

  # A* Search Algorithm
  # @param start_obj - The starting object for the search
  # @param goal_obj - The goal object to search for
  # @param expand_fn - A function to expand the current object into its next nodes
  # @param heuristic_fn - A heuristic function to estimate the cost from the current node to the goal node
  # @return - The walker that reached the goal object or nil if no path was found
  # @example - ```rb
  # #Heuristic function to estimate distance to goal
  # heuristic_fn = ->(walker) {
  #   dx = walker.current.x - goal_obj.x
  #   dy = walker.current.y - goal_obj.y
  #   Math.sqrt(dx*dx + dy*dy)  # Euclidean distance
  # }
  # 
  # # Simultaneous up and downstream walking
  # expand_fn = ->(link, walker) {
  #   nodes = []
  # 
  #   ds_node = link.navigate("ds_node")[0]
  #   nodes += ds_node.navigate("ds_links") if ds_node
  # 
  #   us_node = link.navigate("us_node")[0]
  #   nodes += us_node.navigate("us_links") if us_node
  # 
  #   nodes
  # }
  #
  # start_obj = ...  # The starting object for the search
  # goal_obj = ...   # The goal object to search for
  # result = aStarSearch(start_obj, goal_obj, expand_fn, heuristic_fn)
  # if result
  #   puts "Path found!"
  # else
  #   puts "No path found."
  # end
  def aStarSearch(start_obj, goal_obj, expand_fn, heuristic_fn)
    open_set = [ObjectWalker.new(start_obj, expand_fn: expand_fn)]
  
    while open_set.any?
        # Sort walkers by heuristic (lowest first)
        open_set.sort_by! { |w| w.meta.f_cost || Float::INFINITY }
        walker = open_set.shift
        walker.alive = false
  
        if walker.current == goal_obj
          return walker
        end
  
        next_walkers = walker.next_walkers
        next_walkers.each do |nw|
          nw.meta.g_cost = (walker.meta.g_cost || 0) + 1  # basic cost, can adjust
          nw.meta.h_cost = heuristic_fn.call(nw)
          nw.meta.f_cost = nw.meta.g_cost + nw.meta.h_cost
          open_set << nw
        end
    end
  
    return nil  # no path found
  end

  class ModelWalker
    def initialize(start)
      @start = start
    end
  
    # Downstream trace til a condition is met returning an array of link objects
    #@param start - The starting object for the trace
    #@param block as ->(current: any, walker: ObjectWalker): boolean - A condition to check against the current object. Returning true will stop the trace.
    #@return - An array of link objects that matched the condition in the block
    #Examples:
    #   select ds till you hit a specified manhole id:
    #      result = downstream_trace_until(start_node) {|link| link.ds_node.id == "specific id"}
    #   select ds till you hit a pumping station link or no further links:
    #      result = downstream_trace_until(start_node) {|link| link.link_type[/Pmp/i] || link.ds_node.ds_links.length == 0}
    #   select ds till tracing distance exceeds 20m
    #      result = downstream_trace_until(start_node) {|link,walker| getLength(walker.allLinks) > 20}
    def downstream_trace_until(&block)
      WSModelWalker::icmTraceTilDS(@start, &block).flat_map(&:all_nodes).uniq { |link| link.id }
    end
    
    # Upstream trace til a condition is met returning an array of link objects
    #@param start - The starting object for the trace
    #@param block as ->(current: any, walker: ObjectWalker): boolean - A condition to check against the current object. Returning true will stop the trace.
    #@return - An array of link objects that matched the condition in the block
    #Examples:
    #   select us till you hit a specified manhole id:
    #      result = upstream_trace_until(start_node) {|link| link.us_node.id == "specific id"}
    #   select us till you hit a pumping station link or no further links:
    #      result = upstream_trace_until(start_node) {|link| link.link_type[/Pmp/i] || link.us_node.us_links.length == 0}
    #   select us till tracing distance exceeds 20m
    #      result = upstream_trace_until(start_node) {|link,walker| getLength(walker.allLinks) > 20}
    def upstream_trace_until(&block)
      WSModelWalker::icmTraceTilUS(@start, &block).flat_map(&:all_nodes).uniq { |link| link.id }
    end
  
    def a_star_search(goal_obj, expand_fn, heuristic_fn)
      WSModelWalker::aStarSearch(@start, goal_obj, expand_fn, heuristic_fn).flat_map(&:all_nodes).uniq { |link| link.id }
    end
  end

  def self.new(start_obj)
    ModelWalker.new(start_obj)
  end
end