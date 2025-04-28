module WSSnapshotWalker
    # Create a new SnapshotWalker object from a folder containing snapshot files.
    #@param network [WSOpenNetwork] The network to be used for loading snapshots.
    #@param folder [String] The folder containing the snapshot files.
    #@return [SnapshotWalker] The initialized SnapshotWalker object.
    def CreateFromFolder(network, folder)
        files = Dir.glob(File.join(folder, "*.isfm"))
        return SnapshotWalker.new(network, files)
    end

    # Create a new SnapshotWalker object from a list of snapshot files.
    #@param network [WSOpenNetwork] The network to be used for loading snapshots.
    #@param files [Array<String>] The list of snapshot files to be loaded.
    #@return [SnapshotWalker] The initialized SnapshotWalker object.
    def self.new(network, files)
        return SnapshotWalker.new(network, files)
    end

    # This class is used to walk through a set of snapshot files and load them into the network.
    # It is designed to be used with the Enumerable module to allow for easy iteration over the files.
    # The files are loaded one at a time, and the network is reverted to its original state after each file is loaded.
    #@example 1 - 
    #   ```rb
    #   walker = WSSnapshotWalker::CreateFromFolder(network, folder)
    #   walker.each do |file|
    #       file.load do |network|
    #           # Do something with the network
    #       end
    #   end
    #   ```
    #@example 2 - 
    #   ```rb
    #   walker = WSSnapshotWalker::CreateFromFolder(network, folder)
    #   results = walker.map do |file|
    #       file.load do |network|
    #           # Do something with the network
    #       end
    #   end
    #   ```
    class SnapshotWalker
        include Enumerable

        attr_reader :network, :files

        # Initialize the SnapshotWalker with a network and a list of files.
        #@param network [WSOpenNetwork] The network to be used for loading snapshots.
        #@param files [Array<String>] The list of snapshot files to be loaded.
        #@return [SnapshotWalker] The initialized SnapshotWalker object.
        def initialize(network, files, progress:=nil)
            @network = network
            @files = files
            @progress = progress || Progress.new({:setValue => ->(value, me) {}})
        end
        
        # Iterate over each file in the list of files.
        #@yield [WrappedFile] A WrappedFile object representing the current file.
        def each(&block)
            @progress.split(@files.length) do |progress|
                @files.each do |file|
                    block.call(WrappedFile.new(@network, file, progress))
                end
            end
        end

        # WrappedFile is a class that represents a snapshot file. It can be loaded into the network and reverted back to its original state using the `load` method.
        class WrappedFile
            attr_reader :path

            def initialize(network, path, progress:=nil)
                @network = network
                @path = path
                @progress = progress || Progress.new({:setValue => ->(value, me) {}})
            end

            def load(&block)
                @network.snapshot_import(@path)
                block.call(@network, @path, @progress)
            ensure
                @network.revert
            end
        end
    end

    #Progress always from 0 to 1
    class Progress
        attr_accessor :count
      
        DEFAULTS = {
          setValue: ->(value, me) {},
          setTitle: ->(title) {},
          setMessage: ->(message) {}
        }
      
        def initialize(callbacks, _count = 1.0)
          @callbacks = DEFAULTS.merge(callbacks)
          @count = _count
          @index = 0.0
        end
      
        def step(size = nil)
          size ||= 1.0 / @count.to_f
          raise 'Progress step out of range' if @index >= 1.0
      
          @index += size
          @index = @index.clamp(0.0, 1.0)
          @callbacks[:setValue].call(@index, self)
        end
      
        def step_size
          1.0 / @count.to_f
        end
      
        def split(_count = 0, &block)
          parent = self
          before = @index
      
          child = Progress.new({
                                 setValue: lambda { |_value, _me|
                                   parent.step(_me.step_size * parent.step_size)
                                 },
                                 setTitle: ->(title) { @callbacks[:setTitle].call(title) },
                                 setMessage: ->(message) { @callbacks[:setMessage].call(message) }
                               }, _count)
      
          block.call(child)
      
          # After block, if child didn't finish, finish it
          expected = before + step_size
          if @index < expected
            remainder = expected - @index
            step(remainder)
          end
      
          child
        end
    end
end
