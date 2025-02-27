#Persistent  ; Keeps the script running
#NoEnv       ; Avoids environment variable dependency

; Set the hotkey to trigger typing the clipboard contents (e.g., Ctrl+Shift+V)
Hotkey := "^+v"

; Show a message box when the script starts
MsgBox, The script is active! Press Ctrl+Shift+V to type the clipboard contents.

; Hotkey definition
^+v::
    ; Get the clipboard content
    ClipContent := Clipboard
    ; If there's content in the clipboard, send it as keystrokes
    if (ClipContent != "")
    {
        Send, %ClipContent%
    }
    else
    {
        MsgBox, Clipboard is empty!
    }
return
