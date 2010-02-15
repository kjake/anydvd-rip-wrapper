#include <Debug.au3>
#include <Array.au3>
#include <GUIComboBox.au3>
#include <GuiButton.au3>
#include <GuiConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>

#Region AutoIt3Wrapper directives section
#AutoIt3Wrapper_UseX64=N
#AutoIt3Wrapper_Icon=auto_dvd.ico
#AutoIt3Wrapper_Outfile=c:\auto_dvd.exe
#AutoIt3Wrapper_Outfile_Type=exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Change2CUI=Y
#AutoIt3Wrapper_Res_Field=Homepage|http://code.google.com/p/anydvd-rip-wrapper/
#AutoIt3Wrapper_Res_Field=Build Date|%date%
#AutoIt3Wrapper_Res_Comment=http://code.google.com/p/anydvd-rip-wrapper/
#AutoIt3Wrapper_Res_Description=AnyDVD Rip Wrapper
#AutoIt3Wrapper_Res_Fileversion=0.9.19
#AutoIt3Wrapper_Res_ProductVersion=0.9.19
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_LegalCopyright=GPL
#AutoIt3Wrapper_res_requestedExecutionLevel=highestAvailable
#AutoIt3Wrapper_Run_Tidy=N
#AutoIt3Wrapper_Run_After=copy "%out%" "..\build\auto_dvd.exe"
#EndRegion AutoIt3Wrapper directives section

OnAutoItExitRegister("cleanUp")

Global $g_szName = "AnyDVD Rip Wrapper"
Global $g_szVersion = "0.9.19"
Global $g_szTitle = $g_szName & " " & $g_szVersion
Global $__gsReportWindowTitle_Debug = $g_szTitle
Local $dvd_drive = ""
Local $net_path = ""
Local $rip_how = ""
Local $_MsgBoxTimeout = 0
Local $_ProgramFilesDir = "C:\Program Files" ; I know AutoIt has a macro for this, but it doesn't work well

If WinExists($g_szTitle) Then Exit (1) ; It's already running

AutoItWinSetTitle($g_szTitle)
AutoItSetOption("TrayAutoPause", 0)
AutoItSetOption("WinTitleMatchMode", 2)
TraySetToolTip($g_szTitle);


If @OSArch == "X64" Then
	$_ProgramFilesDir = "C:\Program Files (x86)"
EndIf

If FileExists($_ProgramFilesDir) == 0 Then
	$_ProgramFilesDir = @ProgramFilesDir
EndIf


_ConsoleWrite($g_szTitle & @CRLF);
_ConsoleWrite(@CRLF);

If FileExists($_ProgramFilesDir & "\SlySoft\AnyDVD\AnyDVD.exe") == 0 Then
	Local $hGUI
	_MsgBox("AnyDVD not found in " & $_ProgramFilesDir & "\SlySoft\AnyDVD!" & @LF & "AnyDVD must be installed for this tool to work." & @LF & @LF & "Please install AnyDVD and try again.")
	Exit 1
EndIf

If FileExists($_ProgramFilesDir & "\SlySoft\AnyDVD\AnyTool.exe") == 0 Then
	$retVal = FileInstall(".\AnyTool.exe", $_ProgramFilesDir & "\SlySoft\AnyDVD\")
	If $retVal == 0 Then
		Local $hGUI
		_MsgBox("There was a problem extracting the required file AnyTool.exe. Please report this error.")
		Exit 1
	EndIf
EndIf

If FileExists($_ProgramFilesDir & "\SlySoft\AnyDVD\tcclone.exe") == 0 Then
	$retVal = FileInstall(".\tcclone.exe", $_ProgramFilesDir & "\SlySoft\AnyDVD\")
	If $retVal == 0 Then
		Local $hGUI
		_MsgBox("There was a problem extracting the required file tcclone.exe. Please report this error.")
		Exit 1
	EndIf
EndIf

If (IsArray($CmdLine) And $CmdLine[0] > 0) Then
	If $CmdLine[0] >= 1 Then
		$dvd_drive = $CmdLine[1]
		If DriveStatus($dvd_drive) <> "READY" Then
			_ConsoleWrite("Error! Specified DVD Drive 'NOT READY' or does not contain a disc." & @CRLF);
			Exit 1
		EndIf
	Else
		_ConsoleWrite("Error! DVD Drive not specified." & @CRLF);
		Exit 1
	EndIf
	If $CmdLine[0] >= 2 Then
		$net_path = $CmdLine[2]
		If FileExists($net_path) <> 1 Then
			_ConsoleWrite("Error! Specified Target Path does not exist." & @CRLF);
			Exit 1
		EndIf
	Else
		_ConsoleWrite("Error! Target Path not specified." & @CRLF);
		Exit 1
	EndIf
	If $CmdLine[0] >= 3 Then
		If _ArraySearch($CmdLine, "/BATCH") Then
			$_MsgBoxTimeout = 10
		EndIf
		If _ArraySearch($CmdLine, "/GUI") Then
			Local $hGUI
		EndIf
		If _ArraySearch($CmdLine, "/FULL") Then
			$rip_how = "FULL"
		EndIf
		If _ArraySearch($CmdLine, "/MENU") Then
			$rip_how = "MENU"
		EndIf
		If _ArraySearch($CmdLine, "/MAIN") Then
			$rip_how = "MAIN"
		EndIf
	EndIf
	If $rip_how = "" Then
		$rip_how = "MAIN"
	EndIf
Else
	_ConsoleWrite(StringUpper(StringRegExpReplace(@ScriptName, ".exe", "")) & " <drive> <destination> [/MAIN|/MENU|/FULL] [/GUI] [/BATCH]" & @CRLF);
	_ConsoleWrite(@CRLF);
	_ConsoleWrite("  drive" & @TAB & @TAB & "Specifies the DVD drive to use." & @CRLF);
	_ConsoleWrite("  destination" & @TAB & "Specifies the base directory for the files to be written to." & @CRLF);
	_ConsoleWrite("  /MAIN" & @TAB & @TAB & "Copies only the longest running Title (Default)" & @CRLF);
	_ConsoleWrite("  /MENU" & @TAB & @TAB & "Copies only the longest running Title and" & @CRLF);
	_ConsoleWrite(@TAB & @TAB & "the entire Menu structure." & @CRLF);
	_ConsoleWrite("  /FULL" & @TAB & @TAB & "Copies the entire DVD." & @CRLF);
	_ConsoleWrite("  /GUI" & @TAB & @TAB & "Shows graphical status messages, progress bar and message" & @CRLF);
	_ConsoleWrite(@TAB & @TAB & "boxes during a copy process started from the command-line." & @CRLF);
	_ConsoleWrite("  /BATCH" & @TAB & "Sets a 10 second timeout on for message boxes instead of" & @CRLF);
	_ConsoleWrite(@TAB & @TAB & "waiting for user interaction." & @CRLF);
EndIf

If ($dvd_drive == "" Or $net_path == "") Then
	Local $hGUI
	_ConsoleWrite("Command-line options not specified, showing GUI." & @CRLF);
	; Create GUI
	$hGUI = GUICreate("Rip Settings", 360, 225, -1, -1, 0x94C800CC, 0x00010101)
	GUICtrlCreateGroup("", 12, 7, 336, 176, 0x50000007, 0x00000004)
	GUICtrlCreateLabel("Select DVD Drive:", 24, 26, 100, 20, 0x50020200, 0x00000004)
	$hCombo = _GUICtrlComboBox_Create($hGUI, "", 24, 46, 312, 21, 0x50010303, 0x00000004)
	GUICtrlCreateLabel("Target Folder:", 24, 80, 100, 20, 0x50020200, 0x00000004)
	$targetInput = GUICtrlCreateInput("", 24, 100, 312, 20, 0x50010080, 0x00000204)
	$btnBrowse = GUICtrlCreateButton("Browse...", 258, 120, 78, 23, 0x50010000, 0x00000004)
	GUICtrlCreateLabel("What to Rip:", 24, 133, 100, 20, 0x50020200, 0x00000004)
	$rdoFullDVD = GUICtrlCreateRadio("Full DVD", 24, 153, 63, 23)
	$rdoMainMenu = GUICtrlCreateRadio("Main Movie + Menus", 103, 153, 120, 23)
	$rdoMain = GUICtrlCreateRadio("Main Movie Only", 232, 153, 102, 23)
	GUICtrlSetState($rdoMain, $GUI_CHECKED)
	$btnOK = GUICtrlCreateButton("OK", 183, 196, 75, 23, 0x50030000, 0x00000004)
	$btnCancel = GUICtrlCreateButton("Cancel", 261, 196, 75, 23, 0x50010000, 0x00000004)
	GUISetState()

	; Add Drives
	$cdroms = DriveGetDrive("CDROM")
	_GUICtrlComboBox_BeginUpdate($hCombo)
	For $i = 1 To $cdroms[0]
		$cdLabel = DriveGetLabel($cdroms[$i])
		If @error Then
			$cdLabel = "NO DISC"
		EndIf
		$cd = StringUpper($cdroms[$i] & "\ [" & StringStripWS($cdLabel, 3) & "]")
		_GUICtrlComboBox_AddString($hCombo, $cd)
	Next
	_GUICtrlComboBox_EndUpdate($hCombo)
	_GUICtrlComboBox_SetCurSel($hCombo, 0)

	; Loop until user exits
	While 1
		$_guiMsg = GUIGetMsg()
		Select
			Case $_guiMsg = $GUI_EVENT_CLOSE
				GUIDelete()
				Exit
			Case $_guiMsg = $btnBrowse
				$net_path = FileSelectFolder("Select target folder for DVD output files:", "", 7, GUICtrlRead($targetInput), $hGUI)
				If $net_path <> "" Then
					GUICtrlSetData($targetInput, $net_path)
				EndIf
			Case $_guiMsg = $btnOK
				$arrDVDs = _GUICtrlComboBox_GetListArray($hCombo)
				$arrDVDs_index = _GUICtrlComboBox_GetCurSel($hCombo)
				$dvd_drive = StringLeft($arrDVDs[$arrDVDs_index + 1], 2)
				$net_path = GUICtrlRead($targetInput)
				Select
					Case BitAND(GUICtrlRead($rdoFullDVD), $GUI_CHECKED) = $GUI_CHECKED
						$rip_how = "FULL";
					Case BitAND(GUICtrlRead($rdoMainMenu), $GUI_CHECKED) = $GUI_CHECKED
						$rip_how = "MENU";
					Case BitAND(GUICtrlRead($rdoMain), $GUI_CHECKED) = $GUI_CHECKED
						$rip_how = "MAIN";
				EndSelect
				If DriveStatus($dvd_drive) <> "READY" Then
					_MsgBox("Selected DVD Drive does not appear to have a disc loaded!")
				ElseIf FileExists($net_path) <> 1 Then
					_MsgBox("Specified Target Path does not exist!")
				ElseIf $rip_how == "" Then
					_MsgBox("Please select what to save from your DVD!")
				Else
					GUIDelete()
					ExitLoop
				EndIf
			Case $_guiMsg = $btnCancel
				GUIDelete()
				Exit 0
		EndSelect
	WEnd
EndIf

_ConsoleWriteCRLF("Process started...")
_ConsoleWriteCRLF("")
_ConsoleWriteCRLF("Toggling AnyDVD to Scan inserted disc.")
;; Disable AnyDVD
RunWait('"' & $_ProgramFilesDir & '\SlySoft\AnyDVD\AnyTool.exe" -d', @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
;; Enable AnyDVD
RunWait('"' & $_ProgramFilesDir & '\SlySoft\AnyDVD\AnyTool.exe" -e', @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
If @error Then
	_MsgBox("Unable to control AnyDVD! Please report this error.")
	Exit 1
EndIf

_ConsoleWriteCRLF("Waiting for Drive to become ready...")
Do
	Sleep(500);
Until DriveStatus($dvd_drive) == "READY"

Sleep(500)
$final_path = $net_path & "\" & StringStripWS(DriveGetLabel($dvd_drive), 3)

_ConsoleWriteCRLF("")
_ConsoleWriteCRLF("Using DVD Drive: " & $dvd_drive)
_ConsoleWriteCRLF("Ripping to Target Path: " & $final_path)

If FileExists($final_path) <> 0 Then
	Do
		$final_path = $final_path & "-" & Random(111, 999, 1)
		_ConsoleWriteCRLF("")
		_ConsoleWriteCRLF("Note: Your target path has been modified because the target path already exists.")
		_ConsoleWriteCRLF("This may be because DVD Labels like DVD_VIDEO are popular.")
		_ConsoleWriteCRLF("NEW target path: " & $final_path)
	Until FileExists($final_path) == 0
EndIf

Sleep(500)
_ConsoleWriteCRLF("")

If ($rip_how == "MENU" Or $rip_how == "MAIN") Then
	_ConsoleWriteCRLF("Finding Main Movie Title ID...")
	;; Find Main Titleset
	Local $pid = Run('"' & $_ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" ' & $dvd_drive & '\VIDEO_TS', @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	Local $line
	Local $dvdTitles[1]
	Local $mainDvdTitle = ""
	While 1
		$line = StdoutRead($pid)
		If @error Then ExitLoop
		;_ConsoleWriteCRLF($line)
		$array = StringSplit($line, @CRLF, 1)
		If $array[0] > 1 Then
			_ArrayConcatenate($dvdTitles, $array)
		EndIf
	WEnd

	For $i = 1 To UBound($dvdTitles) - 1
		If StringRegExp($dvdTitles[$i], "(Playback)") Then
			For $j = $i To UBound($dvdTitles) - 1
				;_ConsoleWriteCRLF($dvdTitles[$j])
				If StringRegExp($dvdTitles[$j], "^\|\s(\d+)\|.*|^\|(\d\d)\|.*") Then
					$found = StringRegExp($dvdTitles[$j], "^\|\s(\d+)\|.*|^\|(\d\d)\|.*", 1)
					;_ArrayDisplay($found)
					$mainDvdTitle = $found[UBound($found) - 1]
					ExitLoop
				EndIf
			Next
			ExitLoop
		EndIf
	Next

	If $mainDvdTitle == "" Then
		;Abort
		_MsgBox("Unable to determine the Main Movie Title ID!")
		Exit 1
	EndIf
	$pid = -1
EndIf

;; AnyDVD
Select
	Case $rip_how = "FULL"
		_ConsoleWriteCRLF("Starting rip for whole DVD...")
		Local $_toRun = '"' & $_ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" --force --remux --outpath "' & $final_path & '" ' & $dvd_drive & '\VIDEO_TS all'
	Case $rip_how = "MENU"
		_ConsoleWriteCRLF("Starting rip for Main Movie (DVD Title: " & $mainDvdTitle & ") + Menus...")
		Local $_toRun = '"' & $_ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" --force --menus --remux --outpath "' & $final_path & '" ' & $dvd_drive & '\VIDEO_TS ' & $mainDvdTitle
	Case $rip_how = "MAIN"
		_ConsoleWriteCRLF("Starting rip for Main Movie (DVD Title: " & $mainDvdTitle & ")...")
		Local $_toRun = '"' & $_ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" --force --remux --outpath "' & $final_path & '" ' & $dvd_drive & '\VIDEO_TS ' & $mainDvdTitle
EndSelect

$pid = Run($_toRun, @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)

Sleep(1500) ;Just in-case the process starts and exits fast enough for the next eval to pass

If $pid <= 0 Or ProcessExists($pid) == 0 Then
	$_msg = "Unable to start Rip! Please report this error"
	$STDOUT = StdoutRead($pid)
	$STDERR = StderrRead($pid)
	If $STDOUT <> "" And $STDERR == "" Then
		$_msg &= ": " & @LF & $STDOUT
	ElseIf $STDOUT == "" And $STDERR <> "" Then
		$_msg &= ": " & @LF & $STDERR
	ElseIf $STDOUT <> "" And $STDERR <> "" Then
		$_msg &= ": " & @LF & $STDOUT & @LF & $STDERR
	EndIf
	$_msg &= @LF & "Command: " & $_toRun
	_MsgBox($_msg)
	Exit 1
EndIf

_ConsoleWriteCRLF("")

Local $STDOUT
Local $progress
If IsDeclared("hGUI") Then
	ProgressOn("Rip Progress", "", "", -1, -1, 18)
	ProgressSet(0, "0%")
EndIf

While 1
	$STDOUT = StdoutRead($pid)
	If @error Then ExitLoop
	$progress = StringRegExp($STDOUT, "P (\d+)% (ts.*)", 1)
	If IsArray($progress) Then
		Select
			Case IsDeclared("hGUI") <> 0
				ProgressSet(Int($progress[0]), String(Int($progress[0])) & "%" & @CRLF & $progress[1])
			Case IsDeclared("hGUI") == 0
				_ConsoleWrite(@CR & String(Int($progress[0])) & "% " & $progress[1])
		EndSelect
	EndIf
WEnd

ProcessWaitClose($pid)
_ConsoleWriteCRLF("")
_ConsoleWriteCRLF("Rip Done!")
Sleep(500)


Func _MsgBox($szMsg)
	If IsDeclared("hGUI") Then
		MsgBox(8208, "Error", $szMsg, $_MsgBoxTimeout)
	Else
		_ConsoleWriteError($szMsg & @CRLF)
	EndIf
EndFunc   ;==>_MsgBox

Func _ConsoleWriteCRLF($szMsg)
	If IsDeclared("hGUI") Then
		__Debug_ReportWindowWrite($szMsg & @CRLF)
	Else
		ConsoleWrite($szMsg & @CRLF)
	EndIf
EndFunc   ;==>_ConsoleWriteCRLF

Func _ConsoleWrite($szMsg)
	If IsDeclared("hGUI") Then
		__Debug_ReportWindowWrite($szMsg)
	Else
		ConsoleWrite($szMsg)
	EndIf
EndFunc   ;==>_ConsoleWrite

Func _ConsoleWriteError($szMsg)
	If IsDeclared("hGUI") Then
		__Debug_ReportWindowWrite($szMsg)
	Else
		ConsoleWrite($szMsg)
	EndIf
	Exit 1
EndFunc   ;==>_ConsoleWriteError

Func cleanUp()
	;_ConsoleWriteCRLF ( "Abort!" )
	Sleep(1000)
	ProcessClose("tcclone.exe")
EndFunc   ;==>cleanUp