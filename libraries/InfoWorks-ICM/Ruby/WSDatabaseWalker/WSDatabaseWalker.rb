class WSDatabaseWalker
  include Enumerable

  def initialize(obj = nil, threaded: false)
    @root = obj || WSApplication.current_database
    @threaded = threaded
  end

  def each(&block)
    roots = @root.is_a?(WSDatabase) ? @root.root_model_objects : @root.children

    if @threaded
      threads = roots.enum_for(:each).map { |root| Thread.new { walk(root, 0, &block) } }
      threads.each(&:join)
    else
      roots.each { |root| walk(root, 0, &block) }
    end
  end

  private

  def walk(model_object, depth, &block)
    block.call(model_object, depth)
    return if model_object.children.count == 0

    model_object.children.each do |child|
      walk(child, depth + 1, &block)
    end
  end
end
  