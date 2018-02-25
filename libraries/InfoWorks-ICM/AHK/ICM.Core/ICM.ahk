;Example:
;
;#include path\to\ICM-Toolbar.ahk
;icm := ICM.new(WinExist("ahk_exe InnovyzeWC.exe"))
;if(icm.isReady()){}
;	icm.Toolbar.SharedActions.ExecuteAction(1)
;	icm.WaitTilReady()
;	icm.Toolbar.SharedActions.ExecuteAction(2)
;	icm.WaitTilReady()
;	Msgbox, Finished!
;} else {
;	Msgbox, ICM is currently processing other data.
;}

;Might be useful (AFX Windows Messages and Win32 Functions):
;	https://msdn.microsoft.com/en-us/library/bb982948.aspx
;	https://msdn.microsoft.com/en-us/library/b1bk73h5.aspx
;
;https://msdn.microsoft.com/en-us/library/fy3dthz5.aspx
;https://msdn.microsoft.com/en-us/library/2dhc1abk.aspx#cdatabase__cdatabase
;

#Include %A_LineFile%\..\libs\acc.ahk
#Include %A_LineFile%\..\libs\Win32.ahk

;Dev notes:
;
; * Avoid using classes like - ahk_class Afx:0000000140000000:8:0000000000010005...
;   -> These are unstable as they change from instance to instance.
;
;
;

Class ICM {
	__new(handle) {
		this.hwnd := handle
		
		;Initialise acc and Msg32 elements
		this.__init()
	}
	
	create(){
		;Run ICM and save handle
		
		;Initialise acc and Msg32 elements
		this.__init()
	}
	
	__init(){
	
	}
	
	WaitTilReady(){
		WS_DISABLED := 0x8000000
		
		ErrorLevel=FAIL
		Style := WS_DISABLED
		
		SetTitleMatchMode, RegEx
		
		sleep,30
		while(Style & WS_DISABLED) {
			while(ErrorLevel="FAIL"){
				;Test responsive
				SendMessage, % Msg32.WM_NULL, 0,0,,% "ahk_id " . this.hwnd
			}
			;Test style - Check style of icm elements
			
			;WinGet, Style, Style, ahk_class Afx:0000000140000000:8:0000000000010005:0000000000000000:\d+ % "ahk_id " . this.hwnd
		}
		sleep,30
	}

	isReady(){
		SendMessage, % Msg32.WM_NULL, 0,0,,% "ahk_id " . this.hwnd,,,,250
		return ErrorLevel!="FAIL"
	}

	RunAddon(id){
		;ID = 1:  35080
		;ID = 2:  35081
		;ID = 3:  35082
		; ...
		wParam := 35080 + id - 1
		PostMessage, % Msg32.WM_COMMAND,%wParam%,0,,% "ahk_id " . this.hwnd
	}
	
	Class Geoplans {
		Next(){
			SendMessage, % Msg32.WM_MDIGETACTIVE, , , MDIClient1, % "ahk_id " . this.hwnd
			MDIHwnd := ErrorLevel
			SendMessage, % Msg32.WM_MDINEXT, %MDIHwnd%, 0,MDIClient1, % "ahk_id " . this.hwnd
			
			;Sanity check:
			SendMessage, % Msg32.WM_MDIGETACTIVE, , , MDIClient1, % "ahk_id " . this.hwnd
			if(MDIHwnd <> ErrorLevel){
				return true
			} else {
				;TryAgain
				this.Next()
				return
			}
		}
		Previous(){
			SendMessage, % Msg32.WM_MDIGETACTIVE, , , MDIClient1, % "ahk_id " . this.hwnd
			MDIHwnd := ErrorLevel
			SendMessage, % Msg32.WM_MDINEXT, %MDIHwnd%, 1,MDIClient1, % "ahk_id " . this.hwnd
			
			;Sanity check:
			SendMessage, % Msg32.WM_MDIGETACTIVE, , , MDIClient1, % "ahk_id " . this.hwnd
			if(MDIHwnd <> ErrorLevel){
				return true
			} else {
				;TryAgain
				this.Previous()
				return
			}
		}
		Count(){
			TCM_FIRST:= 0x1300
			TCM_GETITEMCOUNT := TCM_FIRST + 4
			SendMessage, %TCM_GETITEMCOUNT%, 0,0, SysTabControl321,% "ahk_id " . this.hwnd
			return ErrorLevel
			
			;WinGetText, txt, ahk_exe InnovyzeWC.exe
			;RegExReplace(txt,"i)GeoPlan","",count)
			;return count - 2
		}
		ForceRender(){
			;WM_USER := 0x0...
			;GEOPLAN_FORCE_RENDER := WM_USER + 4096
			;hwnd := ICM_Main_Window > "" MDIClient > "GeoPlan - ..." Afx:... > "" AfxFrameOrView120u
			;SendMessage, %GEOPLAN_FORCE_RENDER%, 0,0,,ahk_id %hwnd%
		}
	}
	
	Class MasterDatabase {
		;Potentially useful:
		;https://msdn.microsoft.com/en-us/library/bb982948.aspx
		;; can use WM_GETDLGCODE  to navigate using keyboard
		
		;this.accICM
		;this.hICM
		;this.accAFXMessageControl
		;this.hAFXMessageControl
		;this.accSysListView
		;this.hSysListView
		;this.accMDBPaneW
		;this.hMDBPaneW
		
		__initMDB(){
			if !this.hMDBPaneW {
				;Create a new explorer window
				ICM_New_Explorer := 0x8836
				PostMessage, % Msg32.WM_COMMAND,% ICM_New_Explorer,,,% "ahk_id " . this.hICM
				
				;Get Explorer window
				;#TODO
				;Ideally here we would use WinEvents (so we can use multiple ICM instances)
				winTitle=Master Database ahk_exe InnovyzeWC.exe
				winwait, %winTitle% ,, 2
				hMDBPaneW := winexist(winTitle)
			}
		
		AFXMessageControl := 0xD2A44
		SysListViewControl := 0x9F2296
		
		Find(filter,value){
			this.__initMDB()
			
		}
		
		Class FindFilters {
			byName(name){
				
			}
			byType(type){
				
			}
			byID(id){
				
			}
			byUser(user){
				
			}
			byDescription(desc){
				
			}
			byDate(date){
				
			}
			byHyperlink(link){
				
			}
		}
		
		GetSelectedMDBItemID(SysList="SysListView321"){
			hSysListView := this.hSysListView
			accLV:=Acc_ObjectFromWindow(hSysListView)
			Loop, % accLV.accChildCount -1
			{
				;msgbox , % (accLV.accState(A_Index) & ACCSTATE_SELECTED)
				if((accLV.accState(A_Index) & ACC_STATE.SELECTED))
					return A_Index
			}
		}
		
		Class SelectedItem {
			_getIndex(){
				LVM_GETNEXTITEM := 0x100C
				wParam := -1
				lParam := 0x02	;LVNI_SELECTED
				SendMessage, %LVM_GETNEXTITEM%,%wParam%,%lParam%,,ahk_id %SysListViewControl%
				return ErrorLevel
			}
			open(){
				wParam := 0xDDE0
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%
			}
			propertiesOpen(){
				wParam := 0xDDF8
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			copy(){
				wParam := 0xDDF2
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			move(){
				wParam := 0xDE31
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			compare(){
				wParam := 0xDDEF
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			rename(){
				wParam := 0xDDF1
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			showCommitHistory(){
				wParam := 0xDDE5
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			newItem(index){ ;Model group and Master group only
				;0 based index
				types := ["Model group"
					,"Model network"
					,"Digitisation template"
					,"GeoExplorer"
					,"Custom graph"
					,"Custom report"
					,"Damage Function"
					,"Engineering validation"
					,"Episode collection"
					,"Flow survey"
					,"Ground infiltration"
					,"Groun model TIN"
					,"Inference"
					,"Infinity System configuration"
					,"Inflow"
					,"Initial conditions 1D"
					,"Initial conditions 2D"
					,"Label list"
					,"Layer list"
					,"Level"
					,"Pipe sediment data"
					,"Pollutograph"
					,"Rainfall event"
					,"Regulator"
					,"Results analysis"
					,"Risk analysis run"
					,"Run"
					,"Selection list"
					,"Statistics template"
					,"Stored query"
					,"Theme"
					,"Trade waste"
					,"UPM River Data"
					,"UPM Threshold"
					,"Waste water"
					,"Workspace"]
				wParam := 0xDDE3 + index
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			exportToFile(type){ ; exports to file type. Type defined by 0-based-index in right click > export drop down menu
				wParam := 0xDDE2 + type
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			
			openAs(){
				wParam := 0xDDE1
				lParam := 0x0000
				PostMessage, % Msg32.WM_COMMAND,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			
			;CUSTOM - Would be nice to have
			getIcon(){
				
			}
			getLVIndex(){
			
			}
		}
	}
	
	Class Toolbar {
		Class Menu {
			OpenDatabaseItem(){
				PostMessage, % Msg32.WM_COMMAND,35282,0,,% "ahk_id " . this.hwnd 
			}
			RunRubyScript(){
				PostMessage, % Msg32.WM_COMMAND,35068,0,,% "ahk_id " . this.hwnd
			}
			RunSimulationReport(){
				PostMessage, % Msg32.WM_COMMAND,34431,0,,% "ahk_id " . this.hwnd
			}
			RunAddon(ID){
				;ID = 1:  35080
				;ID = 2:  35081
				;ID = 3:  35082
				; ...
				wParam := 35079+ID
				PostMessage, % Msg32.WM_COMMAND,%wParam%,0,,% "ahk_id " . this.hwnd
			}
			Print(){
				PostMessage, % Msg32.WM_COMMAND,57607,0,,% "ahk_id " . this.hwnd
			}
		}
		
		Class UserActions {
			Open(){
				;Use postmessage to open the user actions dialog
				PostMessage, % Msg32.WM_COMMAND,35282,0,,% "ahk_id " . this.hwnd
			}
			ExecuteAction(id){
				Xpos := 10 + 27*(id-1)
				ControlClick, ToolbarWindow322, % "ahk_id " . this.hwnd, , LEFT, 1, X%Xpos% Y10
			}
			ExecuteByMessage(ID){
				Msgbox, Maybe not implemented
				wParam := 35271 + ID
				controlHwnd := 0
				PostMessage, % Msg32.WM_COMMAND,%wParam%,0,%controlHwnd%,% "ahk_id " . this.hwnd
			}
		}
		
		Class SharedActions {
			Open(){
				;Use postmessage to open the shared actions dialog
				PostMessage, % Msg32.WM_COMMAND,35282,0,,% "ahk_id " . this.hwnd
			}
			ExecuteAction(id){
				Xpos := 10 + 27*(id-1)
				ControlClick, ToolbarWindow323, % "ahk_id " . this.hwnd, , LEFT, 1, X%Xpos% Y10
			}
		}
		
		Class ModellingGridWindows {
			NewWindow(name){
				;name = nodes, links, subcatchments, polygons, lines, points, asset
			}
			NewResultsWindow(name){
				;name = analysis, nodes, links, subcatchments, polygons, lines, points
			}
			SurfacePollutantEditor(){
			
			}
			RTCEditor(){
				
			}
		}
		
		Class 3dNavigation {
			Rotate(){
			
			}
			ZoomInOrOut(){
			
			}
			RecenterOnTarget(){
			
			}
			ZoomToTarget(){
			
			}
			SetObserver(){
			
			}
			Pan(){
			
			}
			FullExtent(){
			
			}
		}
		
		Class Results {
			Graph(){
			
			}
			Grid(){
			
			}
			GraphSelected(){
			
			}
			GridSelected(){
			
			}
			NewFloodSection(){
			
			}
		}
		
		Class GeoExplorer{
			LinkZone(){
			
			}
			OpenAssociatedItem(){
			
			}
			NewZoneWindow(){
			
			}
		}
		
		Class Replace {
			Rewind(){
			
			}
			Step(amount){
			
			}
			Pause(){
			
			}
			Play(){
			
			}
			Record(){
			
			}
			Loop(){
			
			}
			FastForward(){
			
			}
			JumpTo(time){
			
			}
			ReplayOptions(options){
			
			}
			ShowMaxima(){
			
			}
			ClearResults(){
			
			}
		}
		Class GeoPlan {
			;More Geoplan tools
			UpstreamTrace(){
			
			}
			PipeDirection(){
			
			}
			SelectSimilarLinks(){
			
			}
			SelectRiverReaches(){
			
			}
			ReacCrossSection(){
			
			}
			ConveyanceGraph(){
			
			}
			NewInterpolatedSection(){
			
			}
			MoveSelection(){
			
			}
			MakeMeasuredLength(){
			
			}
			Select(){
			
			}
			PolygonSelect(){
			
			}
			DownstreamTrace(){
			
			}
			LongSection(){
			
			}
			3dManhole(){
			
			}
			Label(){
			
			}
			MeasureDistance(){
			
			}
			NewObject(){
			
			}
			NewObjectType(index){
				Control, Choose, %index%, combobox2, % "ahk_id " . this.hwnd
			}
			EditObjectGeometry(){
			
			}
			UseSnapMode(){
			
			}
			Pan(){
			
			}
			ZoomIn(){
			
			}
			ZoomOut(){
			
			}
			Properties(){
			
			}
			FindInGeoplan(id){
			
			}
			getXYZ(){
				;Open "Go to XY" dialog
				wParam := 0x87C6
				lParam := 0
				PostMessage, % Msg32.WM_COMMAND,%wParam%,0,,% "ahk_id " . this.hwnd
				WinWait, Go To XY Coordinates ahk_class #32770 % "ahk_id " . this.hwnd,, 1
				
				;Get X, Y, Zoom
				ControlGetText, x, Edit1, % "ahk_id " . this.hwnd	;X
				ControlGetText, y, Edit2, % "ahk_id " . this.hwnd	;Y
				ControlGetText, z, Edit3, % "ahk_id " . this.hwnd	;Zoom
				
				;Leave dialog
				Control,Check,,Button4,% "ahk_id " . this.hwnd
				
				return [x,y,z]
			}
			getNetworkExtents(){
				;Open "Go to XY" dialog
				wParam := 0x87C6
				lParam := 0
				PostMessage, % Msg32.WM_COMMAND,%wParam%,0,,% "ahk_id " . this.hwnd
				WinWait, Go To XY Coordinates ahk_class #32770 % "ahk_id " . this.hwnd,, 1
				
				;X1:Static4    X2:Static6
				;Y1:Static5    Y2:Static7
				ControlGetText, x1, Static4, % "ahk_id " . this.hwnd	;X1
				ControlGetText, y1, Static5, % "ahk_id " . this.hwnd	;Y1
				ControlGetText, x2, Static6, % "ahk_id " . this.hwnd	;X2
				ControlGetText, y2, Static7, % "ahk_id " . this.hwnd	;Y2
				
				;Leave dialog
				Control,Check,,Button4,% "ahk_id " . this.hwnd
				
				return [x1,y1,x2,y2]
			}
			GoToXY(x,y,z=200){	
				;Open "Go to XY" dialog
				wParam := 0x87C6
				lParam := 0
				PostMessage, % Msg32.WM_COMMAND,%wParam%,0,,% "ahk_id " . this.hwnd
				WinWait, Go To XY Coordinates ahk_class #32770 % "ahk_id " . this.hwnd,, 1
				
				;Set text
				ControlSetText, Edit1,%x%,% "ahk_id " . this.hwnd	;X
				ControlSetText, Edit2,%y%,% "ahk_id " . this.hwnd	;Y
				ControlSetText, Edit3,%z%,% "ahk_id " . this.hwnd	;Zoom
				
				;Save
				Control,Check,,Button3,% "ahk_id " . this.hwnd
				
				;Leave dialog
				Control,Check,,Button4,% "ahk_id " . this.hwnd
				
			}
		}
		
		Class Selection {
			SQLSelect(){
			
			}
			GroupSelection(){
			
			}
			SelectAll(){
			
			}
			DeselectAll(){
			
			}
			SelectionInvert(){
			
			}
			SelectObjectsInSelectedPolygons(){
			
			}
			ReverseSelectedLinks(){
			
			}
			SelectionDelete(){
			
			}
		}
		
		Class Validation {
			Validate(){
			
			}
		}
		
		Class Scenarios {
			Create(){
			
			}
			Select(name){
			
			}
			Delete(){
			
			}
			Rename(){
			
			}
			Manage(){
			
			}
			ExcludedObjects(){
			
			}
			ExcludedObjectsRestore(){
			
			}
		}
		
		Class Windows {
			New(name){
				;name = GeoPlan, LongSection, 3dManhole, 3dNetwork
			}
		}
		
		Class Docking {
			NewWindow(name){
				;name = Group, ThematicKey, DataFlags, SpatialBookmarks, ObjectProperties, JobControl, JobProgress, Output
			}
			MessageLog(){
			
			}
		}
		
		Class Edit {
			Undo(){
			
			}
			Redo(){
			
			}
			Cut(){
			
			}
			Copy(){
			
			}
			Paste(){
			
			}
			UseEditFlag(){
			
			}
			SelectEditFlag(){
			
			}
		}
		
		Class File {
			New(type){
				;type = mdb, tdb
			}
			
			Open(type){
				;type = mdb, tdb
			}
			Print(){
			
			}
			SaveToMDB(){
			
			}
			UpdateFromMDB(){
			
			}
			Revert(){
			
			}
			UserFlags(){
			
			}
			About(){
			
			}
		}
	}

	Class Geoplan {
		LaunchPropsThemes(){
			PostMessage, % Msg32.WM_COMMAND,34547,0,,% "ahk_id " . this.hwnd
		}
		LaunchGISProps(){
			PostMessage, % Msg32.WM_COMMAND,34340,0,,% "ahk_id " . this.hwnd
		}

	}

}






;Other useful information:
;TB_GETBUTTON returns a Pointer to a TBBUTTON struct which contains the data:
;{
;	iBitmap <-- id in imagelist
;	idCommand <-- WM_COMMAND wParam
;	fsState <-- 0 if disabled, TBSTATE_ENABLED if enabled
;	fsStyle (always seems to be autosize)
;	bReserved[0]:0
;	bReserved[1]:0	:
;	dwData
;	iString
;}
;wParam = button index; lParam pointer to TBBUTTON

;TB_BUTTONCOUNT will give you the max iterations of that loop.



; The exact same technique can be used on the drop down menu buttons