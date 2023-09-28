require 'OpenAudit.rb'
require 'pp'

engine = OpenAudit::Engine.new()
audit = engine.run()
pp audit[:results]
path = WSApplication.file_dialog(false, "json", "JSON audit results", "#{Date.today.to_s}-audit-results", false, true)
File.write(path, audit.to_json)