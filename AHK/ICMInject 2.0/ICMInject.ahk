class Injector {
    
	modes      := {}
    scripts    := {}
    addonAddrs := {}
	addonPaths := {}
	callbacks  := {}
	
	activePIDs := {}
	disabledPIDs := {}
	
	;If install is default then overwrite file, else assume custom. Do not overwrite file.
	;If not installed correctly, install and ask for restart
	
	__makeInjector(path=0){
		if path = 0
			path = %A_Appdata%\Innovyze\WorkgroupClient\scripts\injector.rb
		
		rb = 
		(
			require 'win32ole'

			class Sandbox
			  def Sandbox.new()
				return binding
			  end
			end

			invoker = WIN32OLE.connect("{5c172d3c-c8bf-47b0-80a4-a455420a6911}")
			code = invoker.scripts[$$]
			mode = invoker.modes[$$]

			invoker.rbActive($$)
			  case mode 
				when 0
				  Sandbox.new.eval(code,__FILE__,__LINE__)
				when 1
				  eval(code,binding,__FILE__,__LINE__)
				else
				  box = "box" + mode.to_s
				  $boxes ||= {}
				  $boxes[box] ||= Sandbox.new
				  $boxes[box].eval(code,__FILE__,__LINE__)
			  end
			invoker.rbClosing($$)
		)
		
		FileDelete, %path%
		FileAppend, %rb%, %path%
	}
	
	
	__requestRestart(PID){
		if winexist("ahk_exe InnovyzeWC.exe") {
			Msgbox, ICM Requires a restart. Do you want to restart ICM now?
			if ErrorLevel {
				Msgbox, ICM will restart shortly
				WinClose, ahk_exe InnovyzeWC.exe
				RunWait, InnovyzeWC.exe /ICM
			} else {
				this.disabledPIDs[PID]:=True
			}
		}
	}
	
	;3 Possible cases:
	;	Case 1. User does not have a scripts.csv
	;		-> Install scripts.csv -> Ask for ICM to restart -> return 0
	;	Case 2. User has a scripts.csv, however scripts.csv does not contain Inject RubyScript key.
	;		-> Append line to scripts.csv -> Ask for ICM to restart -> return 0
	;	Case 3. User has a scripts.csv AND scripts.csv contains Inject RubyScript key.
	;		-> return 1 (can execute)
	__checkInstall(PID){
		;Define Ruby Path
		rbPath = %A_Appdata%\Innovyze\WorkgroupClient\scripts\injector.rb
		scriptsPath = %A_Appdata%\Innovyze\WorkgroupClient\scripts\scripts.csv
		rbContent := "Inject RubyScript, injector.rb`n"
		
		;Check if already disabled
		if this.disabledPIDs[PID] {
			this.__requestRestart()
			return 0
		}
		
		;If addon has already been evaluated jump straight to execution
		;Note each instance of ICM may have it's own address for ICMInject.rb
		;for this reason we store that data in a dictionary object 'addonAddrs'.
		if (!this.addonAddrs[PID]){
			;Does scripts.csv exist?
			if fileexist(scriptsPath){	;if scripts.csv exists
				;Case 2 & 3
				Loop, read, %scriptsPath% 
				{
					index = A_Index + 1
					If RegexMatch(A_LoopReadLine,"i)Inject RubyScript\s*,\s*(.+)",m){
						;Case 3
						;Index has been found
						this.addonAddrs[PID] := index
						this.addonPaths[PID] := m1
						if this.addonPaths[PID] = "injector.rb" 
							this.__makeInjector()
						return 1
					} else {
						RegexMatch(A_LoopReadLine,"i)Inject RubyScript\s*,\s*(.+)",m)
					}
				}
				
				;Case 2
				;If we get here then scripts.csv must not contain injector.rb
				;So let's add it, ask for a restart and return 0
				FileAppend, %rbContent%, %scriptsPath%
				
				;Create injector script
				this.__makeInjector()
				this.__requestRestart(PID)
				return 0
			} else {
				;Case 1
				FileCreateDir, %scriptsPath%
				content := "Inject RubyScript, injector.rb`n"
				FileAppend, %rbContent%, %rbPath%
				this.__makeInjector()
				this.__requestRestart(PID)
				return 0
			}
		} else {
			if this.addonPaths[PID] = "injector.rb"
				this.__makeInjector()
			return 1
		}
	}
	
	__callAddon(id){
		;ID = 1:  35080
		;ID = 2:  35081
		;ID = 3:  35082
		; ...
		wParam := 35080 + id - 1
		PostMessage, %WM_COMMAND%,%wParam%,0,,ahk_exe InnovyzeWC.exe
	}
	
	execute(rb,mode:=0,PID:=0){
		if !this.__checkInstall(PID)
			return 0
		
		;If PID == 0, use most recent PID
		if PID=0
			WinGet, PID, PID, ahk_exe InnovyzeWC.exe
		
		;Setup Interop parameters for given process
		scripts[PID] := rb
		modes[PID]   := mode
		
		this.__callAddon(addonAddrs[PID])
		
		return 1
	}
	
	executeFile(file,mode:=0,PID:=0){
		ruby=load('%file%')
		return this.execute(ruby,mode,PID)
	}
	
	;Event -  Active
	rbActive(pid){
		activePIDs[pid] := 1
		if callbacks[pid]
			callbacks[pid]("running")
	}
	
	;Event - Closing
	rbClosing(pid){
		activePIDs[pid] := 0
		if callbacks[pid]
			callbacks[pid]("closing")
	}
}

;DEBUGGING:

msgbox, % Injector.__checkInstall(1)












;UNCOMMENT FOR RELEASE:
;----------------------
;		ObjRegisterActive(Injector,"{5c172d3c-c8bf-47b0-80a4-a455420a6911}")
;		
;		;May consider registering this interface under a name, e.g. 
;		;https://msdn.microsoft.com/en-us/library/windows/desktop/ms678477(v=vs.85).aspx
;		;	ProgID := "InfoWorks.Injector"
;		;	CLSID  := "{5c172d3c-c8bf-47b0-80a4-a455420a6911}"
;		;	file_extension := "icmj" ;?
;		
;		
;		#Persistent
;		OnExit Revoke
;		return
;		
;		Revoke:
;		; This "revokes" the object, preventing any new clients from connecting
;		; to it, but doesn't disconnect any clients that are already connected.
;		; In practice, it's quite unnecessary to do this on exit.
;			ObjRegisterActive(ActiveObject, "")
;		ExitApp





/*
	https://autohotkey.com/boards/viewtopic.php?f=6&t=6148
    ObjRegisterActive(Object, CLSID, Flags:=0)
    
        Registers an object as the active object for a given class ID.
        Requires AutoHotkey v1.1.17+; may crash earlier versions.
    
    Object:
            Any AutoHotkey object.
    CLSID:
            A GUID or ProgID of your own making.
            Pass an empty string to revoke (unregister) the object.
    Flags:
            One of the following values:
              0 (ACTIVEOBJECT_STRONG)
              1 (ACTIVEOBJECT_WEAK)
            Defaults to 0.
    
    Related:
        http://goo.gl/KJS4Dp - RegisterActiveObject
        http://goo.gl/no6XAS - ProgID
        http://goo.gl/obfmDc - CreateGUID()
*/
ObjRegisterActive(Object, CLSID, Flags:=0) {
    static cookieJar := {}
    if (!CLSID) {
        if (cookie := cookieJar.Remove(Object)) != ""
            DllCall("oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0)
        return
    }
    if cookieJar[Object]
        throw Exception("Object is already registered", -1)
    VarSetCapacity(_clsid, 16, 0)
    if (hr := DllCall("ole32\CLSIDFromString", "wstr", CLSID, "ptr", &_clsid)) < 0
        throw Exception("Invalid CLSID", -1, CLSID)
    hr := DllCall("oleaut32\RegisterActiveObject"
        , "ptr", &Object, "ptr", &_clsid, "uint", Flags, "uint*", cookie
        , "uint")
    if hr < 0
        throw Exception(format("Error 0x{:x}", hr), -1)
    cookieJar[Object] := cookie
}