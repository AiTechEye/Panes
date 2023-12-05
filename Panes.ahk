#SingleInstance, Force

CoordMode, Mouse, Screen
MouseGetPos, px, py
Item_WSpace := 16
Item_HSpace := 16
Icon_Size := 32
Items_MaxWidth := 6
Items_MaxHeight := 6
Settings_File := "Panes.ini"
Filter := "desktop.ini conf.ini"Settings_File
PanesIcones := StrSplit(GetSetting("icons-for-items"),",")
AlsoShowThisFolder := StrSplit(GetSetting("Include-Folder"),",")

Fade_duration := 100
Subfolder := 0
Current_folder := A_WorkingDir
Window_Flag_Fade := 524288
Window_Flag_Show := 131072
Window_Flag_Hide := 65536
Window_Flag_Fade_Show := Window_Flag_Fade + Window_Flag_Show
Window_Flag_Fade_Hide := Window_Flag_Fade + Window_Flag_Hide 
; ======================= Setup

Start:
Selected_Folder := ""
Selected_Item := ""
Objects := {}
Items := {}
x := 8
y := 32
itemy := Icon_Size
scroll := Icon_Size

; ======================= Window
Theme_color := GetSetting("theme-color")
Theme_Transparency := GetSetting("theme-transparency")

if (Theme_color == "")
	Theme_color = 000000

if (Theme_Transparency == "")
	Theme_Transparency := true

SplitPath Current_folder,DirName
Gui, 1: +owner -SysMenu -Caption +hWndhGui1 +LastFound 
Gui, 1: Font, s8 bold, Segoe UI

Items["Label"] := 4

; ======================= Items

index := 0
Folders := AlsoShowThisFolder.clone()
Folders.InsertAt(0,Current_folder)

if (Folders[Folders.MaxIndex()] == ""){
	Folders.pop()
}

for i, fold in Folders {
	if (i > 0) {
		itemy += (Icon_Size+Item_WSpace)*1.5
	}
	SplitPath, fold,,,, dirname
	x = 8
	y += (Icon_Size+Item_WSpace)*2
	new_label_y := 8+itemy-Icon_Size
	new_line_y := itemy-Item_WSpace

	if (AlsoShowThisFolder.MaxIndex() > 0) {
		Gui, Add, Progress, x%Item_WSpace% y%new_line_y% w290 h2 BackgroundWhite vItemLine%index%
		key = Line%index%
		Items[key] := itemy
		Items["ItemLine"index] := new_line_y
	}

	Gui, 1: Font, s12 bold, Segoe UI
	Gui, Add, Text,cWhite x8 y%new_label_y% vItemLabel%index%, %dirname% 
	Gui, 1: Font, s8 bold, Segoe UI

	key = Label%index%
	Items[key] := itemy
	Items["ItemLabel"index] := new_line_y

	Loop, Files,%fold%\*.*,DF
	{
		index += 1
		if (A_LoopFileExt != "" and InStr(Filter,A_LoopFileExt) or A_LoopFileName == A_ScriptName) {
			continue
		}

		ty := itemy+Icon_Size
		tx := x-Icon_Size/3
		text := SubStr(A_LoopFileName,1,6)
		Gui, Add, Text, w%Icon_Size% h%Icon_Size% X%x% Y%itemy% 0x3 hwndiconid1 gItemSelected vItems%index%

		icon := GetIconForItem(A_LoopFileFullPath)

		if (icon != "") {
			SendMessage, STM_SETICON := 0x0170, icon, 0,, Ahk_ID %iconid1%
		} else {
			SendMessage, STM_SETICON := 0x0170, GetFileIcon(A_LoopFileLongPath), 0,, Ahk_ID %iconid1%
		}

		Gui, Add, Text,cWhite xp y%ty% vItemText%index%, %text%
		key = Items%index%
		Objects[key] := A_LoopFileLongPath
		Items[key] := itemy
		Items["ItemText"index] := ty

		x += Icon_Size + Item_WSpace
		if (x > (Icon_Size + Item_WSpace)*Items_MaxWidth){
			x = 8
			itemy += Icon_Size+Item_WSpace
			if (y < Items_MaxWidth*Icon_Size+Item_WSpace) {
				y := itemy
			}
		}
	}

}

wh := y+32+16

; ======================= Window pos/size


if (Current_folder == A_WorkingDir) {
	Gui, 1: Show, Hide
	WinGetPos ,,,,taksbar_h, ahk_class Shell_TrayWnd
	WinGetPos ,xx,yy,w,h
	taksbar_h += 10


	if (px+w/2 > A_ScreenWidth) {
		xx := A_ScreenWidth-w
	} else if (px-w/2 < 0) {
		xx := 0
	} else {
		xx := px - w/2
	}
	if (py-h < 0) {
		yy := 0
	} else {
		yy := py - h
	}
}

if (py+wh > A_ScreenHeight-taksbar_h)
	yy := (A_ScreenHeight-taksbar_h) - wh*1.5

WinGet, GuiID, ID
Gui, 1: Color, %Theme_color%
Gui, 1: Show, x%xx% y%yy% w290 h%wh% Hide,Panes

WindowId := WinExist()

if (Theme_Transparency == true) {
	EnableBlur(hGui1)
	h := wh*1.5
	WinSet, Region, 0-0 R40-40 w430 h%h%
	WinSet, TransColor, %Theme_color%   , % "ahk_id " hGui1 
} else {
	h := wh*1.5
	WinSet, Region, 0-0 R40-40 w430 h%h%
}

DllCall("AnimateWindow", "UInt",WindowId,"Int",Fade_duration,"UInt",Window_Flag_Fade_Show)
WinSet, ALwaysOnTop, On,Panes
SetTimer Timer
WinActivate, ahk_id %GuiID%

; ======================= ContextMenu & Settings:

Menu, Menu1, Add, Also show this folder, AlsoShowFolder
Menu, Menu1, Add, Change Icon, ChengeIcon
Menu, Menu1, Add, Open Folder, OpenBaseFolder
Menu, Menu1, Add, Open Settings..., ShowSettings

Gui, 2:  +owner -SysMenu +Caption +hWndhGui1 +LastFound 
Gui, 2: Add, Button, x0 y0 w70 h20 gPickColor, Pick a color
Gui, 2: Add, Edit, vColorInput gKColorInput x70 y0 w50
Gui, 2: Add, Checkbox, x120 y0 w100 h20 gSetEnableTransparency vEnableTransparency,Transparent
Gui, 2: Add, Slider, w50 x0 y20 gSetEnableExplore vEnableExplore range0-3
Gui, 2: Add, Text, x50 y20 w200 vEnableExploreText
Gui, 2: Show, x%xx% y%yy% w200 h40 Hide,Panes settings
WinSet, ALwaysOnTop, on,Panes settings

Settings_window := WinExist()

return

; ======================= Functions

*WheelUP::
	my := Icon_Size+Item_WSpace
	 if (scroll >= Icon_Size+Icon_Size) {
		scroll -= my
		for key, v in Items {
			v += my
			Items[key] := v
			GuiControl, Move, %key%,y%v%
	}
	}
return
*WheelDown::
	my := Icon_Size+Item_WSpace
	if (scroll < ty-y) {
		scroll += my
		for key, v in Items {
			v -= my
			Items[key] := v
			GuiControl, Move, %key%,y%v%
		}
	}
return

ItemSelected(){
	Global
	SetTimer, Timer, Off
	sub := GetSetting("explore-folders")
	file := Objects[A_GuiControl]

	if (sub != "" and sub > 0 and Instr(FileExist(file),"D")) {
		if (sub == 3 or Subfolder < sub) {
			SetTimer, Timer, Off
			Subfolder += 1
			Gui 1: Destroy
			Gui 2: Destroy
			Current_folder := file
			Gosub, Start
			return
		}
	}

	Run % file
	ExitApp
	return
}

GetFileIcon(filepath){
	return DllCall("Shell32\ExtractAssociatedIcon" (A_IsUnicode ? "W" : "A"), ptr, DllCall("GetModuleHandle", ptr, 0, ptr), str, filepath, "ushort*", lpiIcon, ptr)
}

GuiClose(){
ExitApp
}
APPClose(){
	Global
	DllCall("AnimateWindow", "UInt",WindowId,"Int",Fade_duration,"UInt",Window_Flag_Fade_Hide)
	Sleep, Fade_duration
	ExitApp
}

Timer:
	IfWinNotActive ahk_id %GuiID%
	{
	SetTimer, Timer, Off
	APPClose()
	}
return

EnableBlur(hWnd) {
	WCA_ACCENT_POLICY := 19
	ACCENT_ENABLE_GRADIENT := 1,
	ACCENT_ENABLE_TRANSPARENTGRADIENT := 2,
	ACCENT_ENABLE_BLURBEHIND := 3,
	ACCENT_INVALID_STATE := 4
	accentStructSize := VarSetCapacity(AccentPolicy, 4*4, 0)
	NumPut(ACCENT_ENABLE_BLURBEHIND, AccentPolicy, 0, "UInt")
	padding := A_PtrSize == 8 ? 4 : 0
	VarSetCapacity(WindowCompositionAttributeData, 4 + padding + A_PtrSize + 4 + padding)
	NumPut(WCA_ACCENT_POLICY, WindowCompositionAttributeData, 0, "UInt")
	NumPut(&AccentPolicy, WindowCompositionAttributeData, 4 + padding, "Ptr")
	NumPut(accentStructSize, WindowCompositionAttributeData, 4 + padding + A_PtrSize,"UInt")
	DllCall("SetWindowCompositionAttribute", "Ptr", hWnd,"Ptr", &WindowCompositionAttributeData)
}


; ContextMenu Functions: ==============================================


GuiContextMenu(GuiHwnd, CtrlHwd, EventInfo, IsRightClick, x, y) {
	Global Objects, AlsoShowThisFolder, PanesIcones
	file := Objects[A_GuiControl]

	Menu, Menu1, UnCheck,Also show this folder

	if (Instr(FileExist(file),"D")) {
		Menu, Menu1, Enable,Also show this folder
		Selected_Folder := file
		for i, line in AlsoShowThisFolder {
			if (line == file) {
				Menu, Menu1, Check,Also show this folder
				break
			}
		}
	} else {
		Menu, Menu1, Disable,Also show this folder
	}

	if (FileExist(file)) {
		Selected_Item := file
		Menu, Menu1, Enable,Change Icon
		Menu, Menu1, UnCheck,Change Icon
		for i, line in PanesIcones {
			f := StrSplit(line,"*")
			if (file == f[1]) {
				Menu, Menu1, Check,Change Icon
				break
			}
		}
	} else {
		Menu, Menu1, Disable,Change Icon
	}

	Menu, Menu1, show
}
return


ChengeIcon:
	Global Selected_Item

	SetTimer, Timer, Off
	text := GetSetting("icons-for-items")
	item := inStr(text,Selected_Item "*")
	if (item > 0) {
		iend := inStr(text,item,",")
		dirico := SubStr(text,item,iend-item+2)
		text := StrReplace(text,dirico,"")
	} else {

		FileSelectFile, file,,,Select icon file,*.ico
		SplitPath, file, path, fullfile, filetype, filename

		if (filetype == "") {
			SetTimer Timer
			return
		} else if (filetype != "ico") {
			msgbox,48,Error,Icon (.ico) Is supported Only
			SetTimer Timer
			return
		}
		text := text Selected_Item "*" file ","

	}
	UpdateSetting("icons-for-items",text)
	PanesIcones := StrSplit(GetSetting("icons-for-items"),",")
	Gui 1: Destroy
	Gui 2: Destroy
	Gosub, Start
return

AlsoShowFolder:
	Global Selected_Folder
	text := GetSetting("Include-Folder")
	if (inStr(text,Selected_Folder ",") > 0) {
		text := StrReplace(text,Selected_Folder ",","")
	} else {
		text := text Selected_Folder ","
	}
	AlsoShowThisFolder := StrSplit(text,",")
	UpdateSetting("Include-Folder",text)

	SetTimer, Timer, Off
	Gui 1: Destroy
	Gui 2: Destroy
	Gosub, Start
return

OpenBaseFolder:
	run, %Current_folder%
return

; Setting Functions: ==============================================

PickColor:
	SetTimer SettingsTimer, Off
	SetTimer SettingsTimerColor
return

SettingsTimerColor:
	CoordMode, Pixel, Screen
	MouseGetPos, px, py
	PixelGetColor, color, px, py, RGB
	GuiControl,2: ,ColorInput,% substr(color,3)
	IfWinNotActive ahk_id %Settings_window%
	{
	WinActivate, ahk_id %Settings_window%
	SetTimer SettingsTimerColor, Off
	SetTimer SettingsTimer
	}
return

SettingsTimer:
	IfWinNotActive ahk_id %Settings_window%
	{
	SetTimer, SettingsTimer, Off
	Gui, 2: Show, hide
	WinActivate, ahk_id %GuiID%
	SetTimer Timer
	}
return

SetEnableTransparency:
	Gui, Submit, NoHide
	UpdateSetting("theme-transparency",EnableTransparency)
	Theme_Transparency := EnableTransparency
return

KColorInput:
	Gui, Submit, NoHide
	UpdateSetting("theme-color",ColorInput)
	Theme_color := ColorInput
	Gui, 1: Color, %ColorInput%
return

SetEnableExplore:
	Gui, Submit, NoHide
	UpdateSetting("explore-folders",EnableExplore)
	UpdateEnableExplore()
return

UpdateEnableExplore() {
	v := GetSetting("explore-folders")
	if (v == 0)
		GuiControl,2: ,EnableExploreText,Open folders
	if (v == 1)
		GuiControl,2: ,EnableExploreText,Explore folders
	if (v == 2)
		GuiControl,2: ,EnableExploreText,Explorer subfolders
	if (v == 3)
		GuiControl,2: ,EnableExploreText,Explorer all subfolders
	GuiControl,2: ,EnableExplore,%v%
	}
return

; Setting Functions: ==============================================

ShowSettings:
	SetTimer, Timer, Off
	color := GetSetting("theme-color")
	GuiControl,2: ,ColorInput,% GetSetting("theme-color")
	GuiControl,2: ,EnableTransparency,% Theme_Transparency
	UpdateEnableExplore()
	Gui, 2: Show
	WinSet, ALwaysOnTop, on, A
	WinActivate, ahk_id %Settings_window%
	SetTimer SettingsTimer
return

UpdateSetting(s,v) {
	a := Load()
	t = [%s%]
	b := instr(a,t)
	c := instr(a,";",false,b)
	if (b == 0 or c == 0) {
		a = %a%`n%t%%v%;
	}
	else {
		tt = %t%%v%;
		a := strreplace(a,substr(a,b,c-b+1),tt)
	}
	Save(a)
	return
}

GetSetting(s) {
	GLOBAL
	l := Load()
	lab = [%s%]
	a := instr(l,lab,false,0)
	b := instr(l,"]",false,a)
	c := instr(l,";",false,b)
	if (a == 0)
		return ""
	return % substr(l,b+1,c-b-1)
}

Save(text) {
	GLOBAL
	File := FileOpen(Settings_File,"w")
	File.Write(text)
	File.close()
	return
}

Load() {
	GLOBAL
	File := FileOpen(Settings_File,"r")
	a := File.read()
	File.close()
	return a
}

LoadFile(file) {
	File := FileOpen(file,"r")
	a := File.read()
	File.close()
	return a
}

GetIconForItem(file) {
	GLOBAL PanesIcones
	for i, line in PanesIcones {
		f := StrSplit(line,"*")
		if (file == f[1] and FileExist(f[2])) {
			return LoadIcon(f[2])
		}
	}
}

LoadIcon(img) {
	FileRead,buf,*c %img%
	icon := DllCall("CreateIconFromResourceEx"
	,UInt,&buf+22
	,UInt,NumGet(buf,14)
	,Int,1
	,UInt,0x30000
	,UInt,48
	,UInt,48
	,UInt,0
	,Ptr)
	return icon
}