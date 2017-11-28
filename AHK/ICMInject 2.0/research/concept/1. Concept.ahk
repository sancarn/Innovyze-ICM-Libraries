; Register our object so that other scripts can get to it.  The second
; parameter is a GUID which I generated.  You should generate one unique
; to your script.  You can use [CreateGUID](http://goo.gl/obfmDc).
ObjRegisterActive(ActiveObject, "{6B39CAA1-A320-4CB0-8DB4-352AA81E460E}")

#Persistent
OnExit Revoke
return

Revoke:
; This "revokes" the object, preventing any new clients from connecting
; to it, but doesn't disconnect any clients that are already connected.
; In practice, it's quite unnecessary to do this on exit.
ObjRegisterActive(ActiveObject, "")
ExitApp

; This is a simple class (object) that clients will interact with.
; You can register any object; it doesn't have to be a class.
class ActiveObject {
    
    ;Property - These have to be static to be transferred as part of the COM object.
    static name := "Bob"
    
    ; Simple message-passing example.
    Message(Data) {
        MsgBox Received message: %Data%
        return 42
    }
    ; "Worker thread" example.
    static WorkQueue := []
    BeginWork(WorkOrder) {
        this.WorkQueue.Insert(WorkOrder)
        SetTimer Work, -100
        return
        Work:
        ActiveObject.Work()
        return
    }
    Work() {
        work := this.WorkQueue.Remove(1)
        ; Pretend we're working.
        Sleep 5000
        ; Tell the boss we're finished.
        work.complete(this)
    }
    Quit() {
        MsgBox Quit was called.
        DetectHiddenWindows On  ; WM_CLOSE=0x10
        PostMessage 0x10,,,, ahk_id %A_ScriptHwnd%
        ; Now return, so the client's call to Quit() succeeds.
    }
}




/*
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