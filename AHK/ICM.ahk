;Example:
;
;#include path\to\ICM-Toolbar.ahk
;if(ICM.isReady()){}
;	ICM.Toolbar.SharedActions.ExecuteAction(1)
;	ICM.WaitTilReady()
;	ICM.Toolbar.SharedActions.ExecuteAction(2)
;	ICM.WaitTilReady()
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

#Include %A_LineFile%\..\Libs\acc.ahk

Global WM_COMMAND = 0x111


Class ICM {

	WaitTilReady(){
		WM_NULL := 0x00
		WS_DISABLED := 0x8000000
		
		ErrorLevel=FAIL
		Style := WS_DISABLED
		
		SetTitleMatchMode, RegEx
		
		sleep,30
		while(Style & WS_DISABLED) {
			while(ErrorLevel="FAIL"){
				;Test responsive
				SendMessage, %WM_NULL%, 0,0,,ahk_exe InnovyzeWC.exe
			}
			;Test style
			WinGet, Style, Style, ahk_class Afx:0000000140000000:8:0000000000010005:0000000000000000:\d+ ahk_exe InnovyzeWC.exe
		}
		sleep,30
	}

	isReady(){
		SendMessage, %WM_NULL%, 0,0,,ahk_exe InnovyzeWC.exe,,,,250
		return ErrorLevel!="FAIL"
	}

	RunAddon(id){
		;ID = 1:  35080
		;ID = 2:  35081
		;ID = 3:  35082
		; ...
		wParam := 35080 + id - 1
		PostMessage, %WM_COMMAND%,%wParam%,0,,ahk_exe InnovyzeWC.exe
	}
	
	Class Geoplans {
		Next(){
			WM_MDIGETACTIVE	= 0x0229
			WM_MDINEXT	= 0x0224
			SendMessage, %WM_MDIGETACTIVE%, , , MDIClient1, ahk_exe InnovyzeWC.exe
			MDIHwnd := ErrorLevel
			SendMessage, %WM_MDINEXT%, %MDIHwnd%, 0,MDIClient1, ahk_exe InnovyzeWC.exe
			
			;Sanity check:
			SendMessage, %WM_MDIGETACTIVE%, , , MDIClient1, ahk_exe InnovyzeWC.exe
			if(MDIHwnd <> ErrorLevel){
				return true
			} else {
				;TryAgain
				this.Next()
				return
			}
		}
		Previous(){
			WM_MDIGETACTIVE	= 0x0229
			WM_MDINEXT	= 0x0224
			SendMessage, %WM_MDIGETACTIVE%, , , MDIClient1, ahk_exe InnovyzeWC.exe
			MDIHwnd := ErrorLevel
			SendMessage, %WM_MDINEXT%, %MDIHwnd%, 1,MDIClient1, ahk_exe InnovyzeWC.exe
			
			;Sanity check:
			SendMessage, %WM_MDIGETACTIVE%, , , MDIClient1, ahk_exe InnovyzeWC.exe
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
			SendMessage, %TCM_GETITEMCOUNT%, 0,0, SysTabControl321,ahk_exe InnovyzeWC.exe
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
		
		;ctrl := "Afx:0000000140000000:8:0000000000010003:0000000001100065:00000000000000001" ;<-- hwnd determined from acc_ahk
		AFXMessageControl := 0xD2A44
		SysListViewControl := 0x9F2296
		
		
		Class FindWindow{
			open(){
				;ICM.MasterDatabase.FindWindow.Open
				wParam := 0x0000DF72
				lParam := 0x00000000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%
			}
		}
		
		GetSelectedMDBItemID(SysList="SysListView321"){
			ControlGet, hSysListView, hwnd, , %SysList%, ahk_exe InnovyzeWC.exe
			accLV:=Acc_ObjectFromWindow(hSysListView)
			Loop, % accLV.accChildCount -1
			{
				;msgbox , % (accLV.accState(A_Index) & ACCSTATE_SELECTED)
				if((accLV.accState(A_Index) & ACCSTATE_SELECTED))
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
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%
			}
			propertiesOpen(){
				wParam := 0xDDF8
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			copy(){
				wParam := 0xDDF2
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			move(){
				wParam := 0xDE31
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			compare(){
				wParam := 0xDDEF
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			rename(){
				wParam := 0xDDF1
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			showCommitHistory(){
				wParam := 0xDDE5
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
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
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			exportToFile(type){ ; exports to file type. Type defined by 0-based-index in right click > export drop down menu
				wParam := 0xDDE2 + type
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
			}
			
			openAs(){
				wParam := 0xDDE1
				lParam := 0x0000
				PostMessage, %WM_COMMAND%,%wParam%,%lParam%,,ahk_id %AFXMessageControl%	
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
				PostMessage, %WM_COMMAND%,35282,0,,ahk_exe InnovyzeWC.exe 
			}
			RunRubyScript(){
				PostMessage, %WM_COMMAND%,35068,0,,ahk_exe InnovyzeWC.exe
			}
			RunSimulationReport(){
				PostMessage, %WM_COMMAND%,34431,0,,ahk_exe InnovyzeWC.exe
			}
			RunAddon(ID){
				;ID = 1:  35080
				;ID = 2:  35081
				;ID = 3:  35082
				; ...
				wParam := 35079+ID
				PostMessage, %WM_COMMAND%,%wParam%,0,,ahk_exe InnovyzeWC.exe
			}
			Print(){
				PostMessage, %WM_COMMAND%,57607,0,,ahk_exe InnovyzeWC.exe
			}
		}
		
		Class UserActions {
			Open(){
				;Use postmessage to open the user actions dialog
				PostMessage, %WM_COMMAND%,35282,0,,ahk_exe InnovyzeWC.exe
			}
			ExecuteAction(id){
				Xpos := 10 + 27*(id-1)
				ControlClick, ToolbarWindow322, ahk_exe InnovyzeWC.exe, , LEFT, 1, X%Xpos% Y10
			}
			ExecuteByMessage(ID){
				Msgbox, Maybe not implemented
				wParam := 35271 + ID
				controlHwnd := 0
				PostMessage, %WM_COMMAND%,%wParam%,0,%controlHwnd%,ahk_exe InnovyzeWC.exe
			}
		}
		
		Class SharedActions {
			Open(){
				;Use postmessage to open the shared actions dialog
				PostMessage, %WM_COMMAND%,35282,0,,ahk_exe InnovyzeWC.exe
			}
			ExecuteAction(id){
				Xpos := 10 + 27*(id-1)
				ControlClick, ToolbarWindow323, ahk_exe InnovyzeWC.exe, , LEFT, 1, X%Xpos% Y10
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
				Control, Choose, %index%, combobox2, ahk_exe InnovyzeWC.exe
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
				PostMessage, %WM_COMMAND%,%wParam%,0,,ahk_exe InnovyzeWC.exe
				WinWait, Go To XY Coordinates ahk_class #32770 ahk_exe InnovyzeWC.exe,, 1
				
				;Get X, Y, Zoom
				ControlGetText, x, Edit1, ahk_exe InnovyzeWC.exe	;X
				ControlGetText, y, Edit2, ahk_exe InnovyzeWC.exe	;Y
				ControlGetText, z, Edit3, ahk_exe InnovyzeWC.exe	;Zoom
				
				;Leave dialog
				Control,Check,,Button4,ahk_exe InnovyzeWC.exe
				
				return [x,y,z]
			}
			getNetworkExtents(){
				;Open "Go to XY" dialog
				wParam := 0x87C6
				lParam := 0
				PostMessage, %WM_COMMAND%,%wParam%,0,,ahk_exe InnovyzeWC.exe
				WinWait, Go To XY Coordinates ahk_class #32770 ahk_exe InnovyzeWC.exe,, 1
				
				;X1:Static4    X2:Static6
				;Y1:Static5    Y2:Static7
				ControlGetText, x1, Static4, ahk_exe InnovyzeWC.exe	;X1
				ControlGetText, y1, Static5, ahk_exe InnovyzeWC.exe	;Y1
				ControlGetText, x2, Static6, ahk_exe InnovyzeWC.exe	;X2
				ControlGetText, y2, Static7, ahk_exe InnovyzeWC.exe	;Y2
				
				;Leave dialog
				Control,Check,,Button4,ahk_exe InnovyzeWC.exe
				
				return [x1,y1,x2,y2]
			}
			GoToXY(x,y,z=200){	
				;Open "Go to XY" dialog
				wParam := 0x87C6
				lParam := 0
				PostMessage, %WM_COMMAND%,%wParam%,0,,ahk_exe InnovyzeWC.exe
				WinWait, Go To XY Coordinates ahk_class #32770 ahk_exe InnovyzeWC.exe,, 1
				
				;Set text
				ControlSetText, Edit1,%x%,ahk_exe InnovyzeWC.exe	;X
				ControlSetText, Edit2,%y%,ahk_exe InnovyzeWC.exe	;Y
				ControlSetText, Edit3,%z%,ahk_exe InnovyzeWC.exe	;Zoom
				
				;Save
				Control,Check,,Button3,ahk_exe InnovyzeWC.exe
				
				;Leave dialog
				Control,Check,,Button4,ahk_exe InnovyzeWC.exe
				
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
			PostMessage, %WM_COMMAND%,34547,0,,ahk_exe InnovyzeWC.exe
		}
		LaunchGISProps(){
			PostMessage, %WM_COMMAND%,34340,0,,ahk_exe InnovyzeWC.exe
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