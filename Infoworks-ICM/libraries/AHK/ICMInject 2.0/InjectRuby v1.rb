#NO PERMISSION TO USE REGISTRY:
#---------------------------------------------------------------------------------------
#require 'win32/registry'
#Win32::Registry::HKEY_CURRENT_USER.create('SOFTWARE','ICMInject') do |reg|
#	#read registry to get path of script to run
#	scriptFile = reg['ScriptFile', Win32::Registry::REG_SZ]
#	
#	
#	if File.exists? scriptFile
#		#read contents of script file
#		script = File.open(scriptFile).read()
#		
#		#execute script
#		eval(script)
#		
#		#set the registry value to blank, indicating execution is about to finish.
#		reg['ScriptFile', Win32::Registry::REG_SZ] = ""
#		reg['Errors', Win32::Registry::REG_SZ] = ""
#	else
#		reg['Errors', Win32::Registry::REG_SZ] = "Script file does not exist."
#	end
#end

#	#USE A PIPE INSTEAD?
#	File.new("\\\\.\\pipe\\icmRubyPipe",'a')
#	> No such file or directory \\.\pipe\icmRubyPipe
#	
#	
#	file=File.open('\\.\\')
#	> Invalid directory
#	
#	file=File.open('\\\\.\\')
#	> Invalid argument


#	ENV['APPDATA']      ==> C:\Users\JWA\AppData\Roaming
#	ENV['LOCALAPPDATA'] ==> C:\Users\JWA\AppData\Local
#
#	ENV['APPDATA'] + '\Innovyze\ICMInjector#{Process::pid.to_s(16)}.rb'

#	ENV.keys
#	>["ALLUSERSPROFILE", "APPDATA", "CommonProgramFiles", "CommonProgramFiles(x86)", "CommonProgramW6432", "COMPUTERNAME", "ComSpec", "FP_NO_HOST_CHECK", "HOME", "HOMEDRIVE", "HOMEPATH", "HOMESHARE", "LOCALAPPDATA", "LOGONSERVER", "NUMBER_OF_PROCESSORS", "OS", "Path", "PATHEXT", "PROCESSOR_ARCHITECTURE", "PROCESSOR_IDENTIFIER", "PROCESSOR_LEVEL", "PROCESSOR_REVISION", "ProgramData", "ProgramFiles", "ProgramFiles(x86)", "ProgramW6432", "PSModulePath", "PUBLIC", "SESSIONNAME", "SystemDrive", "SystemRoot", "TEMP", "TMP", "UATDATA", "USER", "USERDNSDOMAIN", "USERDOMAIN", "USERNAME", "USERPROFILE", "VS110COMNTOOLS", "windir", "windows_tracing_flags", "windows_tracing_logfile"]

class Sandbox
end

[1].each do
	begin
		injector = File.open(ENV['APPDATA'] + "\\Innovyze\\ICMInjector#{$$.to_s(16)}.rb",'r+')
	rescue 
		break
	end
	code = injector.read()
	
	#Empty file and remove all text from it...
	injector.truncate(0)
	injector.close()
	
	#If ruby code contains the line:
	#	execution,sandbox
	#then sandbox the evaluated code
	if /^\s*#\s*ruby\s*,\s*sandbox\s*$/im =~ code
		Sandbox.new.instance_eval(code,__FILE__,__LINE__)
	elsif  /^\s*#\s*ruby\s*,\s*box(\d+)\s*$/im =~ code
		
		box = "box" + $1
		
		if !@@boxes
			@@boxes = {}
		end
		
		if !@@boxes.key? box
			@@boxes[box] = Sandbox.new
		end
		
		@boxes[box].instance_eval(code,__FILE__,__LINE__)
	else
		eval(code,binding,__FILE__,__LINE__)
	end
	
	File.unlink(injector.path)
end