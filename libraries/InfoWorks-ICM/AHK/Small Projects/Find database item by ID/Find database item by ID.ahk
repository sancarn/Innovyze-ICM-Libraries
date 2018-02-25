#SingleInstance, Force
#include libs\acc.ahk

;Sutton in ashfield SMP
oICM := new ICM()
oICM.FindByID(1426)
oICM.FindByID(1162)

Class ICM {
	static hICM
	
	__new(handle=false){
		this.hICM := handle ? handle : winexist("ahk_exe InnovyzeWC.exe")
	}
	
	;Currently not operational, needs debugging`
	__isTabListParent(oAcc,value){
		if oAcc.accName = "" {
			arr:=acc_childrenFilter(oAcc,ACC_FILTERS.byRole,ACC_ROLE.PAGETABLIST,true)
			return arr.length>0
		}
		return false
	}
	
	StandaloneExplorer(){
		if !(hMDBPaneW := winexist("Master Database ahk_exe InnovyzeWC.exe")){
			hICM := this.hICM
			PostMessage, 0x111,0x8836,,,ahk_id %hICM%
			
			;Ideally here we would use WinEvents (so we can use multiple ICM instances) - #TODO
			winTitle=Master Database ahk_exe InnovyzeWC.exe
			winwait, %winTitle% ,, 2
			hMDBPaneW := winexist(winTitle)
		}
		return hMDBPaneW 
	}
	
	FindByID(ID){
		hStandAloneMDB := this.StandaloneExplorer()
		if !hStandAloneMDB
			hStandAloneMDB := this.StandaloneExplorer()
		StandAloneMDB := ACC_ObjectFromWindow(hStandAloneMDB)
		
		;Seek MDB
		tmp := StandAloneMDB
		tmp := acc_childrenFilter(tmp,ACC_FILTERS.byName,"Master Database",true) ;"Master Database" - Window
		tmp := acc_childrenFilter(tmp,ACC_FILTERS.byName,"Master Database",true) ;"Master Database" - Client
		tmp := acc_childrenFilter(tmp,ACC_FILTERS.byName,"Master Database",true) ;"Master Database" - Window
		tmp := acc_childrenFilter(tmp,ACC_FILTERS.byName,"Master Database",true) ;"Master Database" - Client
		tmp := acc_childrenFilter(tmp,ACC_FILTERS.byRole,ACC_ROLE.WINDOW,true)   ;"" - Window
		tmp := acc_childrenFilter(tmp,ACC_FILTERS.byRole,ACC_ROLE.CLIENT,true)   ;"" - Client
		MDB := tmp
		
		;Open "Find in database" window
		hMDB := acc_WindowFromObject(MDB)
		PostMessage, 0x111, 0xDF72, 0, , ahk_id %hMDB%
		
		;Find in MDB
		WinWait,Find in Database ahk_class #32770 ahk_exe InnovyzeWC.exe,,1
		ControlSetText, Edit1,%ID%, Find in Database ahk_class #32770 ahk_exe InnovyzeWC.exe
		Control,ChooseString, ID, Combobox1, Find in Database ahk_class #32770 ahk_exe InnovyzeWC.exe
		Control, Check, , Button1, Find in Database ahk_class #32770 ahk_exe InnovyzeWC.exe
		while WinExist("Find in Database ahk_class #32770 ahk_exe InnovyzeWC.exe")
			sleep, 100
		
		MDBMainW := acc_children(MDB)[1]
		MDBMainC := acc_childrenFilter(MDBMainW,ACC_FILTERS.byRole,ACC_ROLE.CLIENT,true)   ;"" - Client
		MDBFindW := acc_children(MDBMainC)[2]
		MDBFindC := acc_childrenFilter(MDBFindW,ACC_FILTERS.byRole,ACC_ROLE.CLIENT,true)   ;"" - Client
		ListW    := acc_children(MDBFindC)[1]
		ListEl   := acc_childrenFilter(ListW,ACC_FILTERS.byRole,ACC_ROLE.LIST,true)   ;"" - Client
		ListEl.accDoDefaultAction(1)
		
		;Select in tree
		PostMessage, 0x111, 0xDF9A, 0, , ahk_id %hMDB%
	}
}


acc_getRoot(){ ; The root window contains all other windows
	return acc_ObjectFromWindow(dllcall("GetDesktopWindow"))
}

acc_getContext(exe){
	if(exe){
		WinWait,ahk_exe %exe% ahk_class #32768
		WinGet, hwnd, id, ahk_exe %exe% ahk_class #32768
	} else {
		WinWait,ahk_class #32768
		WinGet, hwnd, id, ahk_class #32768
	}
	return acc_ObjectFromWindow(hwnd)
}

acc_getChildNames(obj){
	s=
	items := Acc_Children(obj)
	for  k,item in items
	{
		s .= item.accName() . "`n"
	}
	return s
}

acc_descendents(){ ;recursive acc_children
}