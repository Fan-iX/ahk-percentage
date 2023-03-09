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
if !DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
    DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
NumPut(1, si, 0, "int")
DllCall("gdiplus\GdiplusStartup", "UPtr*", ptoken, "UPtr", &si, "UPtr", 0)

DllCall("RegisterPowerSettingNotification", "UPtr", A_ScriptHwnd)
OnMessage(0x218, "SetPercentage")

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
    Colour := AC ? 0xff008000 : LightTheme ? 0xff000000 : 0xffffffff
    xpos := Percent == 100 ? -7 : Percent > 9 ? -5 : 5

    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", 32, "int", 32, "int", 0, "int", 0x26200A, "UPtr", 0, "UPtr*", pBitmap)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "UPtr", pBitmap, "UPtr*", pGraphics)

    sString := Percent==100 ? "██" : Percent
    Font := "Microsoft YaHei UI"

    if (!A_IsUnicode){
        nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &Font, "int", -1, "uint", 0, "int", 0)
        VarSetCapacity(wFont, nSize*2)
        DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &Font, "int", -1, "UPtr", &wFont, "int", nSize)
    }

    DllCall("gdiplus\GdipCreateFontFamilyFromName", "UPtr", A_IsUnicode ? &Font : &wFont, "uint", 0, "UPtr*", hFamily)
    DllCall("gdiplus\GdipCreateFont", "UPtr", hFamily, "float", 26, "int", 1, "int", 0, "UPtr*", hFont)

    DllCall("gdiplus\GdipCreateSolidFill", "UPtr", Colour, "UPtr*", pBrush)
    DllCall("gdiplus\GdipSetTextRenderingHint", "UPtr", pGraphics, "int", 4)

    if (!A_IsUnicode){
        nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &sString, "int", -1, "UPtr", 0, "int", 0)
        VarSetCapacity(wString, nSize*2)
        DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "UPtr", &sString, "int", -1, "UPtr", &wString, "int", nSize)
    }
    
    VarSetCapacity(RectF, 16, 0)
    NumPut(xpos, RectF, 0, "float")

    DllCall("gdiplus\GdipDrawString", "UPtr", pGraphics, "Str", A_IsUnicode ? sString : wString, "int", -1, "UPtr", hFont, "UPtr", &RectF, "UPtr", 0, "UPtr", pBrush)
    DllCall("gdiplus\GdipDeleteBrush", "UPtr", pBrush)
    DllCall("gdiplus\GdipDeleteFont", "UPtr", hFont)
    DllCall("gdiplus\GdipDeleteFontFamily", "UPtr", hFamily)
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "UPtr", pBitmap, "UPtr*", hBitmap, "int", 0xffffffff)
    DllCall("gdiplus\GdipDisposeImage", "UPtr", pBitmap)
    DllCall("gdiplus\GdipDeleteGraphics", "UPtr", pGraphics)
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
