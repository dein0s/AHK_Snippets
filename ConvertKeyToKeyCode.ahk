; #############################################################################################################
; # This script was originally developed for the TradeMacro (https://github.com/PoE-TradeMacro/POE-TradeMacro)
; # It allows to run script and use hotkeys regardless of the current keyboard layout
; #
; # Github: https://github.com/dein0s
; # Twitter: https://twitter.com/dein0s
; # Discord: dein0s#2248
; #############################################################################################################


Global ENG_US := 0x4090409
Global DetectHiddenWindowsDefault := A_DetectHiddenWindows
Global TitleMatchModeDefault := A_TitleMatchMode
Global FormatIntegerDefault := A_FormatInteger
Global ScriptID := GetCurrentScriptID()
Global ScriptThread := DllCall("GetWindowThreadProcessId", "UInt", ScriptID, "UInt", 0)


SetSettingsExecution() {
  DetectHiddenWindows, On
  SetTitleMatchMode, 2
  SetFormat, integer, H
  Return
}


SetSettingsDefault() {
  Global
  DetectHiddenWindows, %DetectHiddenWindowsDefault%
  SetTitleMatchMode, %TitleMatchModeDefault%
  SetFormat, integer, %FormatIntegerDefault%
  Return
}


GetCurrentScriptID() {
  SetSettingsExecution()
  WinGet, _ScriptID, ID, %A_ScriptName% ahk_class AutoHotkey
  SetSettingsDefault()
  Return _ScriptID
}


GetCurrentLayout() {
  ; Get current keyboard layout for the active script
  Global
  SetSettingsExecution()
  Layout := DllCall("GetKeyboardLayout", "UInt", ScriptThread)
  SetSettingsDefault()
  Return Layout
}


SwitchLayout(LayoutID) {
  ; Switch keyboard layout for the active script
  Global
  SetSettingsExecution()
  ; Switch the script keyboard layout to the layout identical to the active window
  ; 0x50 - WM_INPUTLANGCHANGEREQUEST
  SendMessage, 0x50,, %LayoutID%,, ahk_id %ScriptID%
  ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms724947%28v=vs.85%29.aspx
  ; update user profile and broadcast WM_SETTINGCHANGE message
  DllCall("SystemParametersInfo", "UInt", 0x005A, "UInt", 0, "UInt", LayoutID, "UInt", 2)
  SetSettingsDefault()
  Return
}


CustomGetKeyCode(Key, SC:=true) {
  Global
  Defaultlayout := GetCurrentLayout()
  _KeyCode := (SC=true) ? GetKeySC(Key) : GetKeyVK(Key)
  If (_KeyCode = 0 and Defaultlayout != ENG_US) {
    ; Retrieving key code can fail (0 returned from GetKeySC()/GetKeyVK()) if the Key couldn't be found
    ; in a current keyboard layout (ie. "d" key in a russian layout)  or if it's MouseKey or some MediaKey
    SwitchLayout(ENG_US)
    _KeyCode := (SC=true) ? GetKeySC(Key) : GetKeyVK(Key)
    SwitchLayout(Defaultlayout)
  }
  Return _KeyCode
}


ConvertKeyToCode(Key, SC:=true) {
  NewKey := Key
  KeyPos := 1
  CodePrefix := (SC=true) ? "SC" : "VK"
  ExcludeModifierSymbols := "[^\#\!\^\+\&\<\>\*\~\$\s]+"
  While (KeyPos := RegExMatch(Key, ExcludeModifierSymbols, FoundKey, KeyPos + StrLen(FoundKey))) {
    If !InStr(FoundKey, CodePrefix) {
      KeyCode := CustomGetKeyCode(FoundKey, SC)
      NewKey := (KeyCode = 0) ? NewKey : RegExReplace(NewKey, FoundKey, Format("{1:s}{2:X}", CodePrefix, KeyCode))
    }
  }
  Return NewKey
}


KeyToSC(Key) {
  Return ConvertKeyToCode(Key, true)
}


KeyToVK(Key) {
  Return ConvertKeyToCode(Key, false)
}
