#include <Debug.au3>
#include <Array.au3>
#include <GUIComboBox.au3>
#include <GuiButton.au3>
#include <GuiConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>


OnAutoItExitRegister( "cleanUp" )

$g_szVersion = "AnyDVD Rip Wrapper 0.9.9"
If WinExists($g_szVersion) Then Exit(1) ; It's already running
AutoItWinSetTitle($g_szVersion)

;AutoItSetOption ( "TrayIconDebug", 0 )
AutoItSetOption ( "TrayAutoPause", 0 )
;AutoItSetOption ( "GUIOnEventMode", 1 )
AutoItSetOption ( "WinTitleMatchMode", 2 )
TraySetToolTip ($g_szVersion);


If FileExists(@ProgramFilesDir & "\SlySoft\AnyDVD\AnyDVD.exe") == 0 Then
  MsgBox(4112, "Error", "AnyDVD not found in " & @ProgramFilesDir & "\SlySoft\AnyDVD!" & @LF & "AnyDVD must be installed for this tool to work." & @LF & @LF & "Please install AnyDVD and try again.")
  Exit 1
EndIf

FileInstall ( "AnyTool.exe", @ProgramFilesDir & "\SlySoft\AnyDVD\" )
FileInstall ( "tcclone.exe", @ProgramFilesDir & "\SlySoft\AnyDVD\" )


Local $dvd_drive = ""
Local $net_path = ""
Local $rip_how = ""

ConsoleWrite ($g_szVersion & @CRLF);
ConsoleWrite (@CRLF);

If (IsArray($CmdLine) AND $CmdLine[0]>0) Then
  If $CmdLine[0]>=1 Then
    $dvd_drive = $CmdLine[1]
    If DriveStatus ( $dvd_drive ) <> "READY" Then
      ConsoleWrite ("Error! Specified DVD Drive NOT READY or does not contain a DVD." & @CRLF);
      Exit 1
    EndIf
  Else
    ConsoleWrite ("Error! DVD Drive not specified." & @CRLF);
    Exit 1
  EndIf
  If $CmdLine[0]>=2 Then
    $net_path = $CmdLine[2]
    If FileExists ( $net_path ) <> 1 Then
      ConsoleWrite ("Error! Specified Target Path does not exist." & @CRLF);
      Exit 1
    EndIf
  Else
    ConsoleWrite ("Error! Target Path not specified." & @CRLF);
    Exit 1
  EndIf
  If $CmdLine[0]>=3 Then
    If ($CmdLine[3] == "FULL" OR $CmdLine[3] == "MENU" OR $CmdLine[3] == "MAIN") Then
      $rip_how = $CmdLine[3]
    Else
      ConsoleWrite ("Error! Unknown Rip method Specified." & @CRLF);
      Exit 1      
    EndIf
  Else
    $rip_how = "MAIN"
  EndIf
  If $CmdLine[0]>=4 Then
    If $CmdLine[4] == "GUI" Then
      Local $hGUI
    EndIf
  EndIf
Else
  ConsoleWrite ("Usage: " & @ScriptName & " <DVD_DRIVE> <TARGET_PATH> [FULL|MENU|MAIN] [GUI]" & @CRLF);
  ConsoleWrite (@TAB & "FULL = Rip Whole DVD" & @CRLF);
  ConsoleWrite (@TAB & "MENU = Rip Main Movie + Menus" & @CRLF);
  ConsoleWrite (@TAB & "MAIN = Rip Main Movie Only (Default)" & @CRLF);
  ConsoleWrite (@CRLF);
  ConsoleWrite (@TAB & "GUI  = Show GUI during rip process anyways" & @CRLF);
EndIf

If ($dvd_drive == "" OR $net_path == "") Then
    Local $hGUI
    ConsoleWrite (@CRLF);
    ConsoleWrite ("Command-line Options not specified, showing GUI." & @CRLF);
    ; Create GUI
    $hGUI = GUICreate("Rip Settings", 360, 225, -1, -1, 0x94C800CC, 0x00010101)
    GUICtrlCreateGroup("", 12, 7, 336, 176, 0x50000007, 0x00000004)
    GUICtrlCreateLabel("Select DVD Drive:",24, 26, 100, 20, 0x50020200, 0x00000004)
    $hCombo = _GUICtrlComboBox_Create($hGUI, "", 24, 46, 312, 21, 0x50010303, 0x00000004)
    GUICtrlCreateLabel("Target Folder:",24, 80, 100, 20, 0x50020200, 0x00000004)
    $targetInput = GUICtrlCreateInput("", 24, 100, 312, 20, 0x50010080, 0x00000204)
    $btnBrowse = GUICtrlCreateButton ("Browse...", 258, 120, 78, 23, 0x50010000, 0x00000004)
    GUICtrlCreateLabel("What to Rip:",24, 133, 100, 20, 0x50020200, 0x00000004)
    $rdoFullDVD = GUICtrlCreateRadio ("Full DVD", 24, 153, 63, 23)
    $rdoMainMenu = GUICtrlCreateRadio ("Main Movie + Menus", 103, 153, 120, 23)
    $rdoMain = GUICtrlCreateRadio ("Main Movie Only", 232, 153, 102, 23)
    $btnOK = GUICtrlCreateButton ("OK", 183, 196, 75, 23, 0x50030000, 0x00000004)
    $btnCancel = GUICtrlCreateButton ("Cancel", 261, 196, 75, 23, 0x50010000, 0x00000004)
    GUISetState()

    ; Add Drives
    $cdroms = DriveGetDrive ( "CDROM" )
    _GUICtrlComboBox_BeginUpdate($hCombo)
    For $i = 1 to $cdroms[0]
        $cdLabel = DriveGetLabel ($cdroms[$i])
        If @error Then
          $cdLabel = "NO DISC"
        EndIf
        $cd = StringUpper($cdroms[$i] & "\ [" & StringStripWS($cdLabel,3) & "]")
        _GUICtrlComboBox_AddString($hCombo, $cd)
        
    Next
    _GUICtrlComboBox_EndUpdate($hCombo)
    _GUICtrlComboBox_SetCurSel($hCombo, 0)
    GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

    ; Loop until user exits
    While 1
        $msg = GUIGetMsg()
        Select
          Case $msg = $GUI_EVENT_CLOSE
            GUIDelete()
            Exit
          Case $msg = $btnBrowse
            $net_path = FileSelectFolder ( "Select target folder for DVD output files:", "" , 7, "", $hGUI)
            GUICtrlSetData($targetInput, $net_path)
          Case $msg = $btnOK
            $arrDVDs = _GUICtrlComboBox_GetListArray($hCombo)
            $arrDVDs_index = _GUICtrlComboBox_GetCurSel($hCombo)
            $dvd_drive = StringLeft ($arrDVDs[$arrDVDs_index+1], 2)
            $net_path = GUICtrlRead($targetInput)
            If DriveStatus ( $dvd_drive ) <> "READY" Then
              MsgBox ( 8208, "Error", "Selected DVD Drive does not appear to have a disc loaded!", 0, $hGUI)
            ElseIf FileExists ( $net_path ) <> 1 Then
              MsgBox ( 8208, "Error", "Target path does not appear to exist!", 0, $hGUI)
            ElseIf $rip_how == "" Then
              MsgBox ( 8208, "Error", "Please select what to save from your DVD!", 0, $hGUI)
            Else
              GUIDelete()
              ExitLoop
            EndIf
          Case $msg = $rdoFullDVD And BitAND(GUICtrlRead($rdoFullDVD),$GUI_CHECKED) = $GUI_CHECKED
            $rip_how = "FULL";
          Case $msg = $rdoMainMenu And BitAND(GUICtrlRead($rdoMainMenu),$GUI_CHECKED) = $GUI_CHECKED
            $rip_how = "MENU";
          Case $msg = $rdoMain And BitAND(GUICtrlRead($rdoMain),$GUI_CHECKED) = $GUI_CHECKED
            $rip_how = "MAIN";
          Case $msg = $btnCancel
            GUIDelete()
            Exit
        EndSelect
    WEnd
EndIf

Global $__gsReportWindowTitle_Debug = $g_szVersion
If IsDeclared( "hGUI" ) Then
  __Debug_ReportWindowCreate()
EndIf

msg ( "Process started..." )
msg ( "" )
msg ( "Toggling AnyDVD to Scan inserted disc." )
;; Disable AnyDVD
RunWait('"' & @ProgramFilesDir & '\SlySoft\AnyDVD\AnyTool.exe" -d', @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
;; Enable AnyDVD
RunWait('"' & @ProgramFilesDir & '\SlySoft\AnyDVD\AnyTool.exe" -e', @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
msg ( "Waiting for Drive to become ready..." )
Do
  sleep (500);
Until DriveStatus($dvd_drive) == "READY"

sleep( 500 )
$final_path = $net_path & "\" & StringStripWS(DriveGetLabel( $dvd_drive ),3)

msg ( "" )
msg ( "Using DVD Drive: " & $dvd_drive )
msg ( "Ripping to Target Path: " & $final_path )

If FileExists($final_path) <> 0 Then
  Do
    $final_path = $final_path & "-" & Random(111,999,1)
    msg ( "" )
    msg ( "Note: Your target path has been modified because the target path already exists." ) 
    msg ( "This may be because DVD Labels like DVD_VIDEO are popular." )
    msg ( "NEW target path: " & $final_path )
  Until FileExists($final_path) == 0
EndIf

sleep( 500 )
msg ( "" )

If ($rip_how == "MENU" OR $rip_how == "MAIN") Then
  msg ( "Finding Main Movie Title ID..." )
  ;; Find Main Titleset
  Local $pid = Run('"' & @ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" ' & $dvd_drive & '\VIDEO_TS', @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
  Local $line
  Local $dvdTitles[1]
  Local $mainDvdTitle = ""
  While 1
      $line = StdoutRead($pid)
      If @error Then ExitLoop
      ;msg($line)
      $array = StringSplit($line, @CRLF, 1)
      If $array[0] > 1 Then
        _ArrayConcatenate($dvdTitles, $array)
      EndIf
  Wend

  For $i = 1 to UBound($dvdTitles)-1
    If StringRegExp ( $dvdTitles[$i], "(Playback)" ) Then
      For $j = $i to UBound($dvdTitles)-1
        ;msg($dvdTitles[$j])
        If StringRegExp ( $dvdTitles[$j], "^\|\s(\d+)\|.*|^\|(\d\d)\|.*" ) Then
          $found = StringRegExp ( $dvdTitles[$j], "^\|\s(\d+)\|.*|^\|(\d\d)\|.*", 1 )
          ;_ArrayDisplay($found)
          $mainDvdTitle = $found[UBound($found)-1]
          ExitLoop
        EndIf
      Next
      ExitLoop
    EndIf
  Next
  
  If $mainDvdTitle == "" Then
    ;Abort
    MsgBox ( 8208, "Error", "Unable to determine the Main Movie Title ID!", 0)
    Exit 1
  EndIf
EndIF

;; AnyDVD
Select
  Case $rip_how = "FULL"
    msg ( "Starting rip for whole DVD..." )
    $pid = Run ( '"' & @ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" --force --remux --outpath ' & $final_path & ' ' & $dvd_drive & '\VIDEO_TS all', @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
  Case $rip_how = "MENU"
    msg ( "Starting rip for Main Movie (DVD Title: " & $mainDvdTitle & ") + Menus...")
    $pid = Run ( '"' & @ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" --force --menus --remux --outpath ' & $final_path & ' ' & $dvd_drive & '\VIDEO_TS ' & $mainDvdTitle, @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
  Case $rip_how = "MAIN"
    msg ( "Starting rip for Main Movie (DVD Title: " & $mainDvdTitle & ")...")
    $pid = Run ( '"' & @ProgramFilesDir & '\SlySoft\AnyDVD\tcclone.exe" --force --remux --outpath ' & $final_path & ' ' & $dvd_drive & '\VIDEO_TS ' & $mainDvdTitle, @SystemDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)  
EndSelect

msg ( "" )
  
Local $STDOUT
Local $progress
If IsDeclared( "hGUI" ) Then
  ProgressOn ( "Rip Progress", "", "" , -1, -1, 18 )
  While 1
      $STDOUT = StdoutRead($pid)
      If @error Then ExitLoop
      $progress = StringRegExp ( $STDOUT, "P (\d+)% (ts.*)", 1 )
      If IsArray ( $progress ) Then
        ProgressSet ( Int($progress[0]), String(Int($progress[0])) & "%" & @CRLF & $progress[1] )
      EndIf
  Wend
Else
  While 1
      $STDOUT = StdoutRead($pid)
      If @error Then ExitLoop
      $progress = StringRegExp ( $STDOUT, "P (\d+)% (ts.*)", 1 )
      If IsArray ( $progress ) Then
        msgn (@CR & String(Int($progress[0])) & "% " & $progress[1] )
      EndIf
  Wend
EndIf

ProcessWaitClose ( $pid )
Sleep ( 500 )
msg ( "" )
msg ( "Rip Done!" )
Sleep ( 500 )


Func msg ($szMsg)
  If IsDeclared( "hGUI" ) Then
    __Debug_ReportWindowWrite ( $szMsg & @CRLF )
  Else
    ConsoleWrite ( $szMsg & @CRLF )
  EndIf
EndFunc

Func msgn ($szMsg)
  If IsDeclared( "hGUI" ) Then
    __Debug_ReportWindowWrite ( $szMsg )
  Else
    ConsoleWrite ( $szMsg )
  EndIf
EndFunc

Func cleanUp()
  ;msg ( "Abort!" )
  sleep ( 1000 )
  ProcessClose ( "tcclone.exe" )  
EndFunc