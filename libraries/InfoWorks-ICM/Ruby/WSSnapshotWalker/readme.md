# WSSnapshotWalker

`WSSnapshotWalker` is a simple, composable library for iterating over InfoWorks ICM snapshot (`.isfm`) files, one at a time, and performing analysis on them. This walker does not require ICM Exchange. Run this snapshot walker on an empty model network.

It provides an Enumerable-style interface for easy walking, mapping, and filtering of snapshots, and optionally integrates with a flexible Progress system for fine-grained progress reporting at every level.

## Features


* Walk over snapshot files one-by-one without permanently mutating your network.
* Automatic revert after each file load, so your network stays clean.
* Enumerable support (each, map, filter, etc.) for easy iteration.
* Fully composable progress reporting, supporting nested progress bars if desired.
* Flexible API: integrate into bigger workflows or run standalone.


## Usage

### Basic operations

```rb
walker = WSSnapshotWalker::CreateFromFolder(network, folder_path)

walker.each do |file|
  file.load do |network, path|
    # Do something with the loaded snapshot
    nodes = network.row_objects("_nodes")
    puts "Loaded #{nodes.length} nodes from #{path}"
  end
end
```

### `Enumeration` usage

Because `WSSnapshotWalker` includes `Enumerable`, you can also do:

```rb
results = walker.map do |file|
  file.load do |network, path|
    # Return some result
    network.row_objects("_nodes").size
  end
end
```

### `Progress` usage

`WSSnapshotWalker` supports optional integration with a `Progress` object, allowing clean progress reporting at multiple nested levels.

```rb
top_progress = WSSnapshotWalker::Progress.new(
  setValue: ->(value, _) { puts "Overall progress: #{(value * 100).round}% complete" }
)

walker = WSSnapshotWalker::CreateFromFolder(network, folder_path, progress: top_progress)

walker.each do |file|
  file.load do |network, path, file_progress|
    nodes = network.row_objects("_nodes")
    file_progress.count = nodes.length
    nodes.each { file_progress.step }
  end
end
```

More importantly this can be used with `WSProgressBar`

```rb
require_relative 'lib/WSProgressBarOOP'

pb = WSProgressBar.new()
pb.max = 1.0
top_progress = WSSnapshotWalker::Progress.new(
    setValue: ->(value, _) { pb.value = value },
    setTitle: ->(title){pb.title = title},
    setMessage: ->(message){pb.message = message}
)

walker = WSSnapshotWalker::CreateFromFolder(network, folder_path, progress: top_progress)

walker.each do |file|
  file.load do |network, path, file_progress|
    nodes = network.row_objects("_nodes")
    file_progress.count = nodes.length
    nodes.each { file_progress.step }
  end
end
```
