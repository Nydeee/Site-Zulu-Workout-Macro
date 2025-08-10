#SingleInstance Force
#NoEnv
SetBatchLines, -1
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

configFile := A_ScriptDir "\BenchPressBot.ini"

; =======================
; === USER SETTINGS  ====
; =======================
yellowColor := 0xEAA850     ; Yellow box color
toleranceYellow := 15       ; Tolerance for yellow detection
whiteColor := 0xFFFFFF      ; White line color
toleranceWhite := 3         ; Tolerance for white line
cooldownMs := 2000          ; Wait after pressing space
checkWidth := 100           ; Pixels to the right of yellow to check for white
borderOpacity := 10         ; Border opacity (0-255, lower = more transparent)

macroOn := false
coolingDown := false

; =======================
; === LOAD SAVED AREA ===
; =======================
if FileExist(configFile) {
    IniRead, searchAreaX1, %configFile%, SearchArea, X1, 0
    IniRead, searchAreaY1, %configFile%, SearchArea, Y1, 0
    IniRead, searchAreaX2, %configFile%, SearchArea, X2, %A_ScreenWidth%
    IniRead, searchAreaY2, %configFile%, SearchArea, Y2, %A_ScreenHeight%
} else {
    searchAreaX1 := 0
    searchAreaY1 := 0
    searchAreaX2 := A_ScreenWidth
    searchAreaY2 := A_ScreenHeight
}

; =======================
; === GUI SETUP =========
; =======================
Gui, +AlwaysOnTop +ToolWindow
Gui, Font, s10 Bold, Segoe UI
Gui, Add, Text,, Made by Xzahz

Gui, Font, s9 Norm, Segoe UI
Gui, Add, Text, w260 vStateLbl, State: OFF
Gui, Add, Button, w140 gToggle Section, Toggle Macro (F6)
Gui, Add, Button, w100 gExitNow ys, Exit (F8)

Gui, Add, Text, xs y+15, Search Area:
Gui, Add, Edit, vAreaCoords w340 ReadOnly, (%searchAreaX1%,%searchAreaY1%) → (%searchAreaX2%,%searchAreaY2%)

Gui, Add, Text, xs y+15, Keybinds & Functions:
Gui, Add, Edit, vKeybinds w340 r8 ReadOnly,
(
F6 = Toggle Macro ON/OFF
F8 = Exit Script
F9 = Set Top-Left Corner
F10 = Set Bottom-Right Corner
Red Border = Scanning
Green Pulse = Space Pressed
)
Gui, Show, AutoSize, Bench Press Bot

; =======================
; === HOTKEYS ==========
; =======================
F6::Gosub, Toggle
F8::Gosub, ExitNow

; F9 = set top-left corner
F9::
    MouseGetPos, mx, my
    searchAreaX1 := mx
    searchAreaY1 := my
    SaveArea()
    Gosub, UpdateArea
    ToolTip, Top-left set: X%mx% Y%my%
    SetTimer, ClearTip, -1500
return

; F10 = set bottom-right corner
F10::
    MouseGetPos, mx, my
    searchAreaX2 := mx
    searchAreaY2 := my
    SaveArea()
    Gosub, UpdateArea
    ToolTip, Bottom-right set: X%mx% Y%my%
    SetTimer, ClearTip, -1500
return

ClearTip:
    ToolTip
return

; =======================
; === BORDER ============
; =======================
ShowBorder(color) {
    global searchAreaX1, searchAreaY1, searchAreaX2, searchAreaY2, borderOpacity
    w := searchAreaX2 - searchAreaX1
    h := searchAreaY2 - searchAreaY1

    Gui, BorderOverlay: Destroy
    Gui, BorderOverlay: +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, BorderOverlay: Color, %color%
    WinSet, Transparent, %borderOpacity%
    Gui, BorderOverlay: Show, x%searchAreaX1% y%searchAreaY1% w%w% h%h% NA
}

PulseGreen() {
    ShowBorder("00FF00")
    Sleep, 150
    ShowBorder("EE0000")
}

UpdateArea:
    GuiControl,, AreaCoords, (%searchAreaX1%,%searchAreaY1%) → (%searchAreaX2%,%searchAreaY2%)
    ShowBorder("EE0000") ; default red
return

SaveArea() {
    global searchAreaX1, searchAreaY1, searchAreaX2, searchAreaY2, configFile
    IniWrite, %searchAreaX1%, %configFile%, SearchArea, X1
    IniWrite, %searchAreaY1%, %configFile%, SearchArea, Y1
    IniWrite, %searchAreaX2%, %configFile%, SearchArea, X2
    IniWrite, %searchAreaY2%, %configFile%, SearchArea, Y2
}

; =======================
; === MAIN LOOP ========
; =======================
SetTimer, CheckHit, Off
return

Toggle:
    macroOn := !macroOn
    if (macroOn) {
        SetTimer, CheckHit, 10
        TrayTip, Bench Press Bot, Started!, 1
        GuiControl,, StateLbl, State: ON
    } else {
        SetTimer, CheckHit, Off
        TrayTip, Bench Press Bot, Stopped!, 1
        GuiControl,, StateLbl, State: OFF
        ToolTip
        ShowBorder("EE0000") ; reset to red
    }
return

CheckHit:
    if (coolingDown)
        return

    ; Step 1: Search for yellow box
    PixelSearch, boxX, boxY, %searchAreaX1%, %searchAreaY1%, %searchAreaX2%, %searchAreaY2%, %yellowColor%, %toleranceYellow%, Fast RGB
    if (ErrorLevel) {
        ToolTip, Yellow box not found
        ShowBorder("EE0000") ; red
        return
    }

    ; Step 2: Look for white line at same Y
    whiteX1 := boxX
    whiteY1 := boxY
    whiteX2 := boxX + checkWidth
    whiteY2 := boxY

    PixelSearch, foundX, foundY, %whiteX1%, %whiteY1%, %whiteX2%, %whiteY2%, %whiteColor%, %toleranceWhite%, Fast RGB
    if (!ErrorLevel) {
        ToolTip, White line FOUND! Pressing Space
        Send, {Space}
        PulseGreen()
        coolingDown := true
        SetTimer, EndCooldown, -%cooldownMs%
    }
return

EndCooldown:
    coolingDown := false
    ShowBorder("EE0000")
return

; =======================
; === CLEAN EXIT ========
; =======================
GuiClose:
    Gosub, ExitNow
return

ExitNow:
    SetTimer, CheckHit, Off
    SetTimer, EndCooldown, Off
    Gui, BorderOverlay: Destroy
    ExitApp
