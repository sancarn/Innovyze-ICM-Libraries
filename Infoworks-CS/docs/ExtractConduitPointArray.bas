'Pre requisites:
'* Make a copy of your .IWT / .IWM / .IWC file.
'   * If .IWC, rename  to .ZIP, extract contents and open (.IWM) in MSAccess
'   * If .IWM, open directly in MSAccess (this will spoil the file and will no longer be usable in CS.)
'   * If .IWT, open directly in MSAccess (this will spoil the file and will no longer be usable in CS.)
'* Change us_node_id and link_suffix value to a value from the hw_conduit table.
'* Make sure hw_conduit table is closed before running ExtractDataTest

'If doing it automatically, you can call repair via DAO.RepairDatabase sub-routine.
'You can unzip directly with Shell.Application's Namespace method

Option Compare Database

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
    ByRef Destination As Any, _
    ByRef Source As Any, _
    ByVal length As Long)

'A test method for extracting data out of a currently open InfoWorks CS database open in MSAccess
Sub ExtractDataTest()
    Dim T As Variant
    Dim query As String
    
    'Here I currently use us_node_id and link_suffix to extract data, however ultimately I'd like to loop over
    'all records by row, construct many arrays of input objects and then build a model in real time.
    query = "SELECT * FROM [hw_conduit] WHERE [us_node_id] = ""1181221670"" and [link_suffix]=""1"""
    
    Set T = CurrentDb.OpenRecordset(query, dbOpenDynaset, dbSeeChanges)
    T.Edit
    
    Dim BinData As Variant
    BinData = T("point_array")
    'returns byte array
    '4 bytes = floating point
    '8 bytes = double
    '32 bytes in total ==> [x1,y1,x2,y2] or [x1,y1,x2,y2,x3,y3,x4,y4]
    'most likely the first is correct
    
    'BinData --> Set of 8 Byte Arrays --> Set of doubles --> Ruby for import
    Set BinData = SplitAtSetLength(BinData, 8)
    
    Dim var As Variant
    Dim dbl() As Byte
    For Each var In BinData
        dbl = castVariantToBytes(var)
        Debug.Print BytesToDbl(dbl)
    Next
End Sub

Function castVariantToBytes(ByVal var As Variant) As Byte()
    Dim bytes() As Byte
    Dim length As Integer
    length = UBound(var) - LBound(var) + 1
    ReDim bytes(length)
    For i = 0 To length - 1
        bytes(i) = var(LBound(var) + i)
    Next
    castVariantToBytes = bytes
End Function

Function BytesToDbl(ByRef bytes() As Byte) As Double
  Dim D As Double
  CopyMemory D, bytes(0), LenB(D)
  BytesToDbl = D
End Function

Function SplitAtSetLength(ByVal var As Variant, ByVal chunkLength As Long) As Collection
    Dim iterator As Long, i As Long
    Dim col As New Collection
    Dim arr As Variant
    
    'Iterator keeps track of the current location in the new arrays,
    'using the mod operator. New arrays start at index 0
    iterator = 0
    
    'Type check var (array)
    'If VarType(var) <> vbArray Then
    '    Err.Raise 13, "Module1::SplitAtSetLength()", "Argument 1 (var) must be of type array"
    '    Exit Function
    'End If
    
    'Loop through all indexes in var array
    For i = LBound(var) To UBound(var)
        'If iterator mod chunkLength = 0 we need to try to add the current value to the array
        'but only if i <> lbound. Afterwards we clear the existing array with redim.
        If iterator Mod chunkLength = 0 Then
            If i <> LBound(var) Then col.Add arr
            ReDim arr(chunkLength - 1) As Variant
        End If
        
        'Set array index to value from current index
        arr(iterator Mod chunkLength) = var(i)
        
        'Increase iterator so we modify different parts of the array
        iterator = iterator + 1
    Next
    
    'add the last array as required
    col.Add arr
    
    'Return collection variable
    Set SplitAtSetLength = col
End Function

Function ceil(ByVal num As Double) As Long
    ceil = Int(num) + IIf((num = Int(num)), 0, 1)
End Function
