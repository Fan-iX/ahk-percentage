#SingleInstance, Force
#Persistent
Menu, Tray, Click, ClickCount
Menu, Tray, NoStandard
Menu, Tray, Add, &Refresh, SetPercentage
Menu, Tray, Add, &History, History
Menu, Tray, Add
Menu, Tray, Add, &Exit, Exit
Menu, Tray, Default, &Refresh

; hPercentage[AC:0~1][LightTheme:0~1][Percent:0~100]
hPercentage:={0:{0:{},1:{}},1:{0:{},1:{}}}
Ptr := A_PtrSize ? "UPtr" : "UInt"
if !DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
    DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pToken, "UPtr", &si, "UPtr", 0)

SetPercentage(){
    global hPercentage
    global Percentage
    global AlternatingCurrent
    RegRead, LightTheme, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    VarSetCapacity(powerstatus, 1+1+1+1+4+4)
    DllCall("kernel32.dll\GetSystemPowerStatus", "uint", &powerstatus)
    AC:=*(&powerstatus)
    Percent:=*(&powerstatus+2)
    Percent:=Min(Percent, 100)
    
    if(Percentage!=Percent || AC!=AlternatingCurrent){
        Percentage:=Percent
        AlternatingCurrent:=AC
        hBitmap:=hPercentage[AC][LightTheme][Percent]
        Menu, Tray, Icon, hbitmap:*%hBitmap%
        Menu, Tray, Tip, %Percentage%
    }
}

CreateIcon(AC,LightTheme,Percent) {
    Colour:=AC?"0xff008000":LightTheme?"0xff000000":"0xffffffff"
    xpos:=Percent==100?-7:Percent>9?-5:5

    Ptr := A_PtrSize ? "UPtr" : "UInt"
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", 32, "int", 32, "int", 0, "int", 0x26200A, Ptr, 0, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
    DllCall("gdiplus\GdipGetImageGraphicsContext", Ptr, pBitmap, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)

    sString:=Percent==100?"██":Percent
    Font=Microsoft YaHei UI
    
    if (!A_IsUnicode){
        nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, "uint", 0, "int", 0)
        VarSetCapacity(wFont, nSize*2)
        DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, Ptr, &wFont, "int", nSize)
    }
    
    DllCall("gdiplus\GdipCreateFontFamilyFromName", Ptr, A_IsUnicode ? &Font : &wFont, "uint", 0, A_PtrSize ? "UPtr*" : "UInt*", hFamily)

    DllCall("gdiplus\GdipCreateFont", Ptr, hFamily, "float", 26, "int", 1, "int", 0, A_PtrSize ? "UPtr*" : "UInt*", hFont)


    DllCall("gdiplus\GdipCreateSolidFill", "UInt", Colour, A_PtrSize ? "UPtr*" : "UInt*", pBrush)
    DllCall("gdiplus\GdipSetStringFormatAlign", Ptr, hFormat, "int", 0)
    DllCall("gdiplus\GdipSetTextRenderingHint", Ptr, pGraphics, "int", 4)
    
    
    if (!A_IsUnicode){
        nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, 0, "int", 0)
        VarSetCapacity(wString, nSize*2)
        DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, &wString, "int", nSize)
    }
    
    VarSetCapacity(RectF, 16)
    NumPut(xpos, RectF, 0, "float"), NumPut(ypos, RectF, 4, "float"), NumPut(Width, RectF, 8, "float"), NumPut(Height, RectF, 12, "float")

    DllCall("gdiplus\GdipDrawString", Ptr, pGraphics, Ptr, A_IsUnicode ? &sString : &wString, "int", -1, Ptr, hFont, Ptr, &RectF, Ptr, hFormat, Ptr, pBrush)
    DllCall("gdiplus\GdipDeleteBrush", Ptr, pBrush)
    DllCall("gdiplus\GdipDeleteStringFormat", Ptr, hFormat)
    DllCall("gdiplus\GdipDeleteFont", Ptr, hFont)
    DllCall("gdiplus\GdipDeleteFontFamily", Ptr, hFamily)
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", Ptr, pBitmap, A_PtrSize ? "UPtr*" : "uint*", hBitmap, "int", 0xffffffff)
    DllCall("gdiplus\GdipDisposeImage", Ptr, pBitmap)
    DllCall("gdiplus\GdipDeleteGraphics", Ptr, pGraphics)
    return %hBitmap%
}

for _,AC in [0,1]
  for _,LightTheme in [0,1]
    loop, 100 {
        hPercentage[AC][LightTheme][A_Index]:=CreateIcon(AC,LightTheme,A_Index)
    }

SetPercentage()
SetTimer, SetPercentage, 1000

History(){
    KeyHistory
}

Exit(){
    ExitApp
}