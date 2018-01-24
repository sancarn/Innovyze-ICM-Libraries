## Infoworks API Wishlist

### Run a ruby script when opening ICM

This would be one of the most useful things that Innovyze could implement to ICM. The ability to load a ruby script when ICM is started is of paramount importance to all these other futures. It would be nice if this `startup.rb` script would be in the `%AppData%` folder. However, it is also vital to give the user the opportunity to change this location through a UI option/preference `Tools > Options... `.

### Customisation of menus and toolbars

Whenever users want to execute an action, they use a toolbar or a menubar. This is such a priority, as there is currently no official way to programatically assign a toolbar for addins or otherwise.

* WSToolBar - Allow users to add and remove custom toolbars / toolbar-items
* WSMenuBar - Allow users to add custom menu bars, in any menu bar item (File, Edit, Network, Selection, Geoplan, Model, Results, Actions, Tools, Window, Help,...)
* WSRowObjectInfo - Allow users to add custom buttons next to user text fields which execute predefined tasks when viewed with the info tool.

### Geoplan - User experience

One of the major parts in ICM is the Geoplan. Users spend maybe 80% of their time navigating in the geoplan, and using geoplan tools. If the geoplan is such a central part of ICM, why are there no implementations to modify and extend the user's own experience in the geoplan?!

* WSApplication.OpenGeoplans() - returns a ruby array of WSGeoplan objects.
* WSGeoplan               - Allow users to completely modify the state of the geoplan. Including, themes, open layers, geoplan extents, center position, zoom, set coordinate system, set online map projection, show/hide locator window, set/unset target, manage labels, turn on/off snapping, manage spatial bookmarks.
* WSGeoplan.focussed      - `True` if this geoplan is the one which is currently focussed/active. `False` if geoplan is not focussed/active.
* WSGeoplan.WSContextMenu - Allow users to add items to context menu of geoplan windows
* WSGeoplan.WSOpenTheme   - Allow users to programatically create themes
* WSGeoplan.WSOpenLayers  - Allow users to programatically add, remove and change the theme of open layers in geoplan.
* WSGeoplan.WSLabels      - Allow users to programatically generate labels on the map. Also allow for these labels to be customisable (full html/js intergration if possible)!
* WSGeoplan.WSCursor      - Allow users to programatically create new, custom cursors. For example, someone might want a radius selector cursor.
* WSGeoplan.WSBookmarks   - Allow users to add, remove and modify spatial bookmarks.
* WSGeoplan.Export(type,path,options) - Allow users to export current view to kml and autocad files

### Events

Event based programming is one of the most important aspects of programming in the modern era. Being able to listen for events is vital for ICM. This could lead to developers adding custom keyboard shortcuts, cursor behaviour, database opening behaviour, database closing behaviour, etc.

Example:

```ruby
WSApplication.on("Open Database") do |database|
    open('some\log.txt', 'a') do |f|
        f.puts "Opened on: #{Time.now.strftime("%d/%m/%Y %H:%M")}, By: '#{ENV['USERNAME']}'."
    end
end

WSApplication.on("Open Transportable") do |database|
    open('some\transportable_log.txt', 'a') do |f|
        f.puts "Opened on: #{Time.now.strftime("%d/%m/%Y %H:%M")}, By: '#{ENV['USERNAME']}'."
    end
end

WSApplication.on("Open Network") do |net|
    updateFromGIS(net)
end

WSApplication.on("Close Network") do |net|
    updateToGIS(net)
end

WSApplication.on("Geoplan.SelectionChange") do |geoplan,net|
    #...
end

#...
```
