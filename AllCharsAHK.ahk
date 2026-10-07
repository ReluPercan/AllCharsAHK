#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; AllCharsAHK.ahk
; Script AutoHotkey v2 pentru simularea aplicației AllChars (suport Unicode).
;
; Copyright (c) 2026 Relu Percan
; SPDX-License-Identifier: MIT
;
; Acest program este distribuit sub termenii Licenței MIT.
; Consultați fișierul LICENSE atașat proiectului pentru textul complet.
;
; ACEST SOFTWARE ESTE FURNIZAT "CA ATARE" (AS IS), FĂRĂ NICIUN FEL DE GARANȚIE.
; ==============================================================================

; --- Stare și Variabile Globale ---
Global Limba := ""
Global TimpSec := 2.0
Global DimFont := 16
Global DimFontRare := 20
Global CombHelp := "c h h"
Global CombRareUnic := "c j j"
Global CombSiruri := "c j k"
Global CombMltSir := "c k j"
Global RareUnic := ""
Global RareUnicLines := []
Global SiruriList := []

; Mapari: Map(ActivatorCode -> Map(SequenceKeyString -> Struct(Valoare, LineNum, RawLine)))
Global Mapari := Map()
Global FerestreDeschise := false
Global FereastraCurenta := ""
Global TargetHwnd := 0

; Hotkey Special Action Identifiers
Global ACTION_HELP := "__ACTION_HELP__"
Global ACTION_RARE := "__ACTION_RARE__"
Global ACTION_SIRURI := "__ACTION_SIRURI__"
Global ACTION_MULSIR := "__ACTION_MULSIR__"

; ==============================================================================
; Modul Internaționalizare (i18n: Română / Engleză / Germană)
; ==============================================================================

DetecteazaLimbaSistem() {
    langId := DllCall("GetUserDefaultUILanguage", "UShort")
    primaryLang := langId & 0xFF
    if (primaryLang == 0x18) ; Română (0x0418)
        return "ro"
    if (primaryLang == 0x07) ; Germană (Standard 0x0407, Elveția 0x0807, Austria 0x0C07 etc.)
        return "de"
    return "en" ; Implicit Engleză
}

ObtineLimbaCurenta() {
    limbaLower := StrLower(Trim(Limba))
    if (limbaLower == "ro" || limbaLower == "en" || limbaLower == "de")
        return limbaLower
    return DetecteazaLimbaSistem()
}

Global I18N := Map(
    "ro", Map(
        "HELP_TITLE", "AllCharsAHK - Ajutor",
        "HELP_VARS_HDR", "=== VARIABILE GLOBALE ===",
        "HELP_MAPS_HDR", "=== MAPĂRI SECVENȚE TASTE ===",
        "HELP_ACTION_HELP", "[Fereastră Ajutor]",
        "HELP_ACTION_RARE", "[Panou Caractere Rare]",
        "HELP_ACTION_SIRURI", "[Fereastră Șiruri]",
        "HELP_ACTION_MULSIR", "[Fereastră MulSir]",
        "BTN_CLOSE", "Închide",
        "SIRURI_TITLE", "AllCharsAHK - Șiruri",
        "SIRURI_EMPTY", "Lista variabilei Siruri este goală! Nu există șiruri de afișat.",
        "RARE_TITLE", "AllCharsAHK - Caractere Rare",
        "RARE_EMPTY", "Variabila RareUnic este goală! Nu există caractere de afișat.",
        "MULSIR_TITLE", "AllCharsAHK - Multiplică Șir",
        "MULSIR_LBL_SRC", "Caracter/Sir:",
        "MULSIR_BTN_GEN", "Generare",
        "MULSIR_LBL_RES", "rezultat:",
        "MULSIR_BTN_SEND", "Trimite",
        "MULSIR_ERR_COUNT", "Valoarea numărului de multiplicări nu poate fi 0 sau vidă!",
        "MULSIR_ERR_TITLE", "AllCharsAHK - Eroare MulSir",
        "CFG_ERR_NOT_FOUND", "Fișierul de configurare AllCharsAHK.cfg nu a fost găsit în directorul scriptului!`n`nCalea căutată: ",
        "CFG_ERR_NOT_FOUND_TITLE", "AllCharsAHK - Eroare Configurare",
        "CFG_ERR_LINE_FMT", "Linia {1}: {2}",
        "CFG_ERR_REDEF_TITLE", "AllCharsAHK - Eroare Redefinire",
        "CFG_ERR_REDEF_HDR", "Eroare în fișierul de configurare AllCharsAHK.cfg:`nRedefinirea unei secvențe de taste!`n`nSecvența de taste redefinită: ",
        "CFG_ERR_REDEF_LINES", "Liniile afectate:",
        "CFG_ERR_REDEF_STOP", "Execuția scriptului a fost oprită.",
        "CFG_ERR_AMBIG_TITLE", "AllCharsAHK - Eroare Ambiguitate",
        "CFG_ERR_AMBIG_HDR", "Eroare în fișierul de configurare AllCharsAHK.cfg:`nAmbiguitate detectată în secvențele de taste!`n`n",
        "CFG_ERR_AMBIG_PREFIX", "Secvența mai scurtă ({1}) este prefix exact al secvenței mai lungi ({2}) pentru tasta activator {3}.`n`n",
        "CFG_ERR_AMBIG_LINES", "Mapările care cauzează ambiguitatea:",
        "CFG_ERR_AMBIG_STOP", "Execuția scriptului a fost oprită.",
        "TRAY_HELP", "Ajutor",
        "TRAY_RELOAD", "Reîncarcă",
        "TRAY_EXIT", "Ieșire"
    ),
    "en", Map(
        "HELP_TITLE", "AllCharsAHK - Help",
        "HELP_VARS_HDR", "=== GLOBAL VARIABLES ===",
        "HELP_MAPS_HDR", "=== KEY SEQUENCE MAPPINGS ===",
        "HELP_ACTION_HELP", "[Help Window]",
        "HELP_ACTION_RARE", "[Rare Characters Panel]",
        "HELP_ACTION_SIRURI", "[Strings Window]",
        "HELP_ACTION_MULSIR", "[Multi-String Window]",
        "BTN_CLOSE", "Close",
        "SIRURI_TITLE", "AllCharsAHK - Strings",
        "SIRURI_EMPTY", "The Siruri/Strings list is empty! No strings to display.",
        "RARE_TITLE", "AllCharsAHK - Rare Characters",
        "RARE_EMPTY", "The RareUnic/RareChars variable is empty! No characters to display.",
        "MULSIR_TITLE", "AllCharsAHK - Multiply String",
        "MULSIR_LBL_SRC", "Char/String:",
        "MULSIR_BTN_GEN", "Generate",
        "MULSIR_LBL_RES", "Result:",
        "MULSIR_BTN_SEND", "Send",
        "MULSIR_ERR_COUNT", "The multiplication count cannot be 0 or empty!",
        "MULSIR_ERR_TITLE", "AllCharsAHK - MulSir Error",
        "CFG_ERR_NOT_FOUND", "Configuration file AllCharsAHK.cfg was not found in the script directory!`n`nSearched path: ",
        "CFG_ERR_NOT_FOUND_TITLE", "AllCharsAHK - Configuration Error",
        "CFG_ERR_LINE_FMT", "Line {1}: {2}",
        "CFG_ERR_REDEF_TITLE", "AllCharsAHK - Redefinition Error",
        "CFG_ERR_REDEF_HDR", "Error in configuration file AllCharsAHK.cfg:`nKey sequence redefinition!`n`nRedefined key sequence: ",
        "CFG_ERR_REDEF_LINES", "Affected lines:",
        "CFG_ERR_REDEF_STOP", "Script execution has been stopped.",
        "CFG_ERR_AMBIG_TITLE", "AllCharsAHK - Ambiguity Error",
        "CFG_ERR_AMBIG_HDR", "Error in configuration file AllCharsAHK.cfg:`nAmbiguity detected in key sequences!`n`n",
        "CFG_ERR_AMBIG_PREFIX", "The shorter sequence ({1}) is an exact prefix of the longer sequence ({2}) for activator key {3}.`n`n",
        "CFG_ERR_AMBIG_LINES", "Mappings causing the ambiguity:",
        "CFG_ERR_AMBIG_STOP", "Script execution has been stopped.",
        "TRAY_HELP", "Help",
        "TRAY_RELOAD", "Reload",
        "TRAY_EXIT", "Exit"
    ),
    "de", Map(
        "HELP_TITLE", "AllCharsAHK - Hilfe",
        "HELP_VARS_HDR", "=== GLOBALE VARIABLEN ===",
        "HELP_MAPS_HDR", "=== TASTENSEQUENZ-ZUORDNUNGEN ===",
        "HELP_ACTION_HELP", "[Hilfefenster]",
        "HELP_ACTION_RARE", "[Seltene Zeichen Panel]",
        "HELP_ACTION_SIRURI", "[Textbausteine Fenster]",
        "HELP_ACTION_MULSIR", "[Multi-String Fenster]",
        "BTN_CLOSE", "Schließen",
        "SIRURI_TITLE", "AllCharsAHK - Textbausteine",
        "SIRURI_EMPTY", "Die Liste der Textbausteine ist leer! Keine Zeichenfolgen vorhanden.",
        "RARE_TITLE", "AllCharsAHK - Seltene Zeichen",
        "RARE_EMPTY", "Die Variable RareUnic/RareChars ist leer! Keine Zeichen vorhanden.",
        "MULSIR_TITLE", "AllCharsAHK - Zeichenfolge vervielfachen",
        "MULSIR_LBL_SRC", "Zeichen/Text:",
        "MULSIR_BTN_GEN", "Generieren",
        "MULSIR_LBL_RES", "Ergebnis:",
        "MULSIR_BTN_SEND", "Senden",
        "MULSIR_ERR_COUNT", "Die Anzahl der Wiederholungen darf nicht 0 oder leer sein!",
        "MULSIR_ERR_TITLE", "AllCharsAHK - MulSir Fehler",
        "CFG_ERR_NOT_FOUND", "Die Konfigurationsdatei AllCharsAHK.cfg wurde im Skriptverzeichnis nicht gefunden!`n`nGesuchter Pfad: ",
        "CFG_ERR_NOT_FOUND_TITLE", "AllCharsAHK - Konfigurationsfehler",
        "CFG_ERR_LINE_FMT", "Zeile {1}: {2}",
        "CFG_ERR_REDEF_TITLE", "AllCharsAHK - Neudefinitionsfehler",
        "CFG_ERR_REDEF_HDR", "Fehler in AllCharsAHK.cfg:`nTastensequenz doppelt definiert!`n`nNeudefinierte Tastensequenz: ",
        "CFG_ERR_REDEF_LINES", "Betroffene Zeilen:",
        "CFG_ERR_REDEF_STOP", "Skriptausführung wurde gestoppt.",
        "CFG_ERR_AMBIG_TITLE", "AllCharsAHK - Mehrdeutigkeitsfehler",
        "CFG_ERR_AMBIG_HDR", "Fehler in AllCharsAHK.cfg:`nMehrdeutigkeit in Tastensequenzen erkannt!`n`n",
        "CFG_ERR_AMBIG_PREFIX", "Die kürzere Sequenz ({1}) ist ein echtes Präfix der längeren Sequenz ({2}) für die Aktivierungstaste {3}.`n`n",
        "CFG_ERR_AMBIG_LINES", "Verursachende Zuordnungen:",
        "CFG_ERR_AMBIG_STOP", "Skriptausführung wurde gestoppt.",
        "TRAY_HELP", "Hilfe",
        "TRAY_RELOAD", "Neu laden",
        "TRAY_EXIT", "Beenden"
    )
)

T(cheie) {
    lang := ObtineLimbaCurenta()
    if I18N.Has(lang) && I18N[lang].Has(cheie)
        return I18N[lang][cheie]
    if I18N["en"].Has(cheie)
        return I18N["en"][cheie]
    return cheie
}

ConfigureazaTrayMenu() {
    try {
        A_TrayMenu.Delete()
        A_TrayMenu.Add(T("TRAY_HELP"), (*) => ArataAjutor())
        A_TrayMenu.Add(T("TRAY_RELOAD"), (*) => Reload())
        A_TrayMenu.Add() ; Separator
        A_TrayMenu.Add(T("TRAY_EXIT"), (*) => ExitApp())
        A_TrayMenu.Default := T("TRAY_HELP")
        A_IconTip := "AllCharsAHK"
    }
}

InchideFereastraActiva(*) {
    Global FerestreDeschise, FereastraCurenta, TargetHwnd
    if (FereastraCurenta) {
        try {
            HotIfWinActive("ahk_id " FereastraCurenta.Hwnd)
            Hotkey("Enter", "Off")
        }
        try AutoScroller.Cleanup(FereastraCurenta.Hwnd)
        try FereastraCurenta.Destroy()
        FereastraCurenta := ""
    }
    FerestreDeschise := false
    if (TargetHwnd) {
        try WinActivate("ahk_id " TargetHwnd)
        TargetHwnd := 0
    }
}

; ==============================================================================
; Manager Derulare Automată (AutoScroller)
; Asigură suport complet pentru derulare VScroll/HScroll și rotiță mouse
; ==============================================================================

Class AutoScroller {
    Static ActiveGuis := Map()

    Static Setup(guiObj, contentW, contentH, parentHwnd := 0) {
        hwnd := guiObj.Hwnd
        
        dpi := DllCall("GetDpiForWindow", "Ptr", hwnd, "UInt")
        if (!dpi)
            dpi := A_ScreenDPI
        scale := dpi / 96.0

        contentW := Integer(contentW * scale)
        contentH := Integer(contentH * scale)

        rect := Buffer(16, 0)
        DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rect)
        clientW := NumGet(rect, 8, "Int")
        clientH := NumGet(rect, 12, "Int")

        needsV := (contentH > clientH)
        needsH := (contentW > clientW)

        if (!needsV && !needsH) {
            return
        }

        info := {
            Hwnd: hwnd,
            Gui: guiObj,
            ContentW: contentW,
            ContentH: contentH,
            ClientW: clientW,
            ClientH: clientH,
            PosX: 0,
            PosY: 0,
            NeedsV: needsV,
            NeedsH: needsH,
            ParentHwnd: parentHwnd
        }
        
        this.ActiveGuis[hwnd] := info
        if (parentHwnd)
            this.ActiveGuis[parentHwnd] := info

        if (needsV) {
            this.SetScroll(hwnd, 1, 0, contentH, clientH, 0)
        }
        if (needsH) {
            this.SetScroll(hwnd, 0, 0, contentW, clientW, 0)
        }

        OnMessage(0x0115, this.OnVScroll.Bind(this))
        OnMessage(0x0114, this.OnHScroll.Bind(this))
        OnMessage(0x020A, this.OnMouseWheel.Bind(this))
    }

    Static Cleanup(hwnd) {
        if this.ActiveGuis.Has(hwnd) {
            info := this.ActiveGuis[hwnd]
            if (info.ParentHwnd && this.ActiveGuis.Has(info.ParentHwnd))
                this.ActiveGuis.Delete(info.ParentHwnd)
            if this.ActiveGuis.Has(info.Hwnd)
                this.ActiveGuis.Delete(info.Hwnd)
        }
    }

    Static SetScroll(hwnd, barType, minVal, maxVal, pageVal, posVal) {
        si := Buffer(28, 0)
        NumPut("UInt", 28, si, 0)
        NumPut("UInt", 0x17, si, 4) ; SIF_ALL
        NumPut("Int", minVal, si, 8)
        NumPut("Int", maxVal, si, 12)
        NumPut("UInt", pageVal, si, 16)
        NumPut("Int", posVal, si, 20)
        DllCall("SetScrollInfo", "Ptr", hwnd, "Int", barType, "Ptr", si, "Int", 1)
    }

    Static GetScrollPos(hwnd, barType) {
        si := Buffer(28, 0)
        NumPut("UInt", 28, si, 0)
        NumPut("UInt", 0x17, si, 4)
        DllCall("GetScrollInfo", "Ptr", hwnd, "Int", barType, "Ptr", si)
        return {
            Min: NumGet(si, 8, "Int"),
            Max: NumGet(si, 12, "Int"),
            Page: NumGet(si, 16, "UInt"),
            Pos: NumGet(si, 20, "Int"),
            TrackPos: NumGet(si, 24, "Int")
        }
    }

    Static ScrollTo(targetKey, barType, newPos) {
        if !this.ActiveGuis.Has(targetKey)
            return

        info := this.ActiveGuis[targetKey]
        hwnd := info.Hwnd
        curPos := (barType == 1) ? info.PosY : info.PosX
        maxPos := (barType == 1) ? (info.ContentH - info.ClientH) : (info.ContentW - info.ClientW)
        if (maxPos < 0)
            maxPos := 0

        newPos := Max(0, Min(newPos, maxPos))
        if (newPos == curPos)
            return

        delta := curPos - newPos

        if (barType == 1) {
            info.PosY := newPos
            this.SetScroll(hwnd, 1, 0, info.ContentH, info.ClientH, newPos)
            DllCall("ScrollWindowEx", "Ptr", hwnd, "Int", 0, "Int", delta, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt", 0x0007)
        } else {
            info.PosX := newPos
            this.SetScroll(hwnd, 0, 0, info.ContentW, info.ClientW, newPos)
            DllCall("ScrollWindowEx", "Ptr", hwnd, "Int", delta, "Int", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt", 0x0007)
        }
        DllCall("UpdateWindow", "Ptr", hwnd)
    }

    Static OnVScroll(wParam, lParam, msg, hwnd) {
        if !this.ActiveGuis.Has(hwnd)
            return
        info := this.ActiveGuis[hwnd]
        actualHwnd := info.Hwnd
        action := wParam & 0xFFFF
        cur := this.GetScrollPos(actualHwnd, 1)

        switch action {
            case 0: ; SB_LINEUP
                this.ScrollTo(hwnd, 1, info.PosY - 30)
            case 1: ; SB_LINEDOWN
                this.ScrollTo(hwnd, 1, info.PosY + 30)
            case 2: ; SB_PAGEUP
                this.ScrollTo(hwnd, 1, info.PosY - info.ClientH)
            case 3: ; SB_PAGEDOWN
                this.ScrollTo(hwnd, 1, info.PosY + info.ClientH)
            case 4, 5: ; SB_THUMBPOSITION, SB_THUMBTRACK
                this.ScrollTo(hwnd, 1, cur.TrackPos)
            case 6: ; SB_TOP
                this.ScrollTo(hwnd, 1, 0)
            case 7: ; SB_BOTTOM
                this.ScrollTo(hwnd, 1, info.ContentH)
        }
    }

    Static OnHScroll(wParam, lParam, msg, hwnd) {
        if !this.ActiveGuis.Has(hwnd)
            return
        info := this.ActiveGuis[hwnd]
        actualHwnd := info.Hwnd
        action := wParam & 0xFFFF
        cur := this.GetScrollPos(actualHwnd, 0)

        switch action {
            case 0: ; SB_LINELEFT
                this.ScrollTo(hwnd, 0, info.PosX - 30)
            case 1: ; SB_LINERIGHT
                this.ScrollTo(hwnd, 0, info.PosX + 30)
            case 2: ; SB_PAGELEFT
                this.ScrollTo(hwnd, 0, info.PosX - info.ClientW)
            case 3: ; SB_PAGERIGHT
                this.ScrollTo(hwnd, 0, info.PosX + info.ClientW)
            case 4, 5: ; SB_THUMBPOSITION, SB_THUMBTRACK
                this.ScrollTo(hwnd, 0, cur.TrackPos)
            case 6: ; SB_LEFT
                this.ScrollTo(hwnd, 0, 0)
            case 7: ; SB_RIGHT
                this.ScrollTo(hwnd, 0, info.ContentW)
        }
    }

    Static OnMouseWheel(wParam, lParam, msg, hwnd) {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mX, &mY, &winUnder)
        if this.ActiveGuis.Has(winUnder) {
            info := this.ActiveGuis[winUnder]
            if (info.NeedsV) {
                delta := (wParam >> 16)
                if (delta > 0x7FFF)
                    delta -= 0x10000
                step := (delta > 0) ? -60 : 60
                this.ScrollTo(winUnder, 1, info.PosY + step)
                return 0
            }
        }
    }
}

; ==============================================================================
; Funcții Utilitare și Parsare
; ==============================================================================

EliminaComentariu(line) {
    len := StrLen(line)
    inEsc := false
    loop len {
        ch := SubStr(line, A_Index, 1)
        if (ch == "\" && !inEsc) {
            inEsc := true
            continue
        }
        if (ch == "#" && !inEsc) {
            line := SubStr(line, 1, A_Index - 1)
            break
        }
        inEsc := false
    }
    return Trim(line, " `t")
}

DecodeEscapes(str) {
    MARK_BACKSLASH := Chr(0x1F001)
    MARK_HASH      := Chr(0x1F002)
    MARK_QUOTE     := Chr(0x1F003)
    MARK_NL        := Chr(0x1F004)
    MARK_CR        := Chr(0x1F005)

    res := str
    res := StrReplace(res, "\\", MARK_BACKSLASH)
    res := StrReplace(res, "\#", MARK_HASH)
    res := StrReplace(res, '\"', MARK_QUOTE)
    res := StrReplace(res, "\n", MARK_NL)
    res := StrReplace(res, "\r", MARK_CR)

    res := StrReplace(res, MARK_BACKSLASH, "\")
    res := StrReplace(res, MARK_HASH, "#")
    res := StrReplace(res, MARK_QUOTE, '"')
    res := StrReplace(res, MARK_NL, "`n")
    res := StrReplace(res, MARK_CR, "`r")

    return res
}

DecodeMulSirEscapes(str) {
    MARK_BACKSLASH := Chr(0x1F001)
    MARK_NL        := Chr(0x1F004)
    MARK_CR        := Chr(0x1F005)
    MARK_TAB       := Chr(0x1F006)

    res := str
    res := StrReplace(res, "\\", MARK_BACKSLASH)
    res := StrReplace(res, "\n", MARK_NL)
    res := StrReplace(res, "\r", MARK_CR)
    res := StrReplace(res, "\t", MARK_TAB)

    res := StrReplace(res, MARK_BACKSLASH, "\")
    res := StrReplace(res, MARK_NL, "`n")
    res := StrReplace(res, MARK_CR, "`r")
    res := StrReplace(res, MARK_TAB, "`t")

    return res
}

ExpandActivator(actStr) {
    actLower := StrLower(Trim(actStr))
    switch actLower {
        case "lc", "lctrl": return ["lc"]
        case "rc", "rctrl": return ["rc"]
        case "c", "ctrl", "control": return ["lc", "rc"]
        case "ls", "lshift": return ["ls"]
        case "rs", "rshift": return ["rs"]
        case "s", "shift": return ["ls", "rs"]
        case "la", "lalt": return ["la"]
        case "ra", "ralt": return ["ra"]
        case "a", "alt": return ["la", "ra"]
        default: return []
    }
}

NumeActivatorDetaliat(code) {
    switch StrLower(code) {
        case "lc": return "LCtrl"
        case "rc": return "RCtrl"
        case "ls": return "LShift"
        case "rs": return "RShift"
        case "la": return "LAlt"
        case "ra": return "RAlt"
        default: return code
    }
}

ExtrageGraphemeClusters(str) {
    clusters := []
    pos := 1
    ; Recunoaste caractere compuse: perechi de steaguri regionale, secvente ZWJ (ex: 👨‍💻) si modificatori de ton
    pat := "(?:[\x{1F1E6}-\x{1F1FF}]{2}|\X[\x{1F3FB}-\x{1F3FF}]?)(?:\x{200D}(?:[\x{1F1E6}-\x{1F1FF}]{2}|\X[\x{1F3FB}-\x{1F3FF}]?))*"
    while (pos := RegExMatch(str, pat, &m, pos)) {
        clusters.Push(m[0])
        pos += m.Len[0]
    }
    return clusters
}

IsPrefixArray(arr1, arr2) {
    if (arr1.Length >= arr2.Length)
        return false
    for idx, val in arr1 {
        if (arr2[idx] != val)
            return false
    }
    return true
}

PadRight(str, totalLen) {
    pad := totalLen - StrLen(str)
    if (pad <= 0)
        return str
    spaces := ""
    loop pad
        spaces .= " "
    return str . spaces
}

; ==============================================================================
; Încărcare și Validare Configurare (AllCharsAHK.cfg)
; ==============================================================================

IncarcaSiValideazaConfig() {
    ConfigFile := A_ScriptDir "\AllCharsAHK.cfg"
    if !FileExist(ConfigFile) {
        MsgBox(T("CFG_ERR_NOT_FOUND") ConfigFile, T("CFG_ERR_NOT_FOUND_TITLE"), "Iconx 0x40000")
        ExitApp()
    }

    FileContent := FileRead(ConfigFile, "UTF-8")
    
    Global Limba := ""
    ; Scanare preliminara pentru Limba / Language pentru a afisa erorile de parsare in limba dorita
    Loop Parse, FileContent, "`n", "`r" {
        lineClean := EliminaComentariu(A_LoopField)
        if InStr(lineClean, "=") {
            parts := StrSplit(lineClean, "=", , 2)
            kLower := StrLower(Trim(parts[1]))
            if (kLower = "limba" || kLower = "language") {
                vTrim := Trim(parts[2], " `t`"'")
                Global Limba := StrLower(vTrim)
                break
            }
        }
    }

    Global RareUnic := ""
    Global RareUnicLines := []
    Global SiruriList := []
    RawMappings := []

    Loop Parse, FileContent, "`n", "`r" {
        LineNum := A_Index
        RawLine := A_LoopField
        LineClean := EliminaComentariu(RawLine)

        if (LineClean == "")
            continue

        if InStr(LineClean, "->") {
            parts := StrSplit(LineClean, "->", , 2)
            stanga := Trim(parts[1])
            dreapta := parts[2]

            stangaNorm := RegExReplace(stanga, "\s+", " ")
            keyTokens := StrSplit(stangaNorm, " ")

            if (keyTokens.Length < 2)
                continue

            rawAct := keyTokens.RemoveAt(1)
            
            decodedKeys := []
            for k in keyTokens {
                decodedKeys.Push(DecodeEscapes(k))
            }

            valTrim := Trim(dreapta, " `t")
            if (SubStr(valTrim, 1, 1) == '"' && SubStr(valTrim, -1) == '"' && StrLen(valTrim) >= 2) {
                valText := SubStr(valTrim, 2, StrLen(valTrim) - 2)
                valFinal := DecodeEscapes(valText)
            } else {
                valFinal := DecodeEscapes(valTrim)
            }

            RawMappings.Push({
                RawAct: rawAct,
                Keys: decodedKeys,
                Val: valFinal,
                LineNum: LineNum,
                RawLine: Trim(RawLine, " `t`r`n")
            })
        } else if InStr(LineClean, "=") {
            parts := StrSplit(LineClean, "=", , 2)
            key := Trim(parts[1])
            val := Trim(parts[2])
            kLower := StrLower(key)

            if (kLower = "timpsec" || kLower = "timeoutsec" || kLower = "timeout") {
                Global TimpSec := Float(val)
            } else if (kLower = "dimfont" || kLower = "fontsize") {
                Global DimFont := Integer(val)
            } else if (kLower = "dimfontrare" || kLower = "rarefontsize") {
                Global DimFontRare := Integer(val)
            } else if (kLower = "combhelp") {
                Global CombHelp := RegExReplace(Trim(val), "\s+", " ")
            } else if (kLower = "combrareunic" || kLower = "combrarechars") {
                Global CombRareUnic := RegExReplace(Trim(val), "\s+", " ")
            } else if (kLower = "combsiruri" || kLower = "combstrings") {
                Global CombSiruri := RegExReplace(Trim(val), "\s+", " ")
            } else if (kLower = "combmltsir" || kLower = "combmultistrings") {
                Global CombMltSir := RegExReplace(Trim(val), "\s+", " ")
            } else if (kLower = "limba" || kLower = "language") {
                valTrim := Trim(val, " `t`"'")
                Global Limba := StrLower(valTrim)
            } else if (kLower = "siruri" || kLower = "strings") {
                valTrim := Trim(val, " `t")
                if (SubStr(valTrim, 1, 1) == '"' && SubStr(valTrim, -1) == '"' && StrLen(valTrim) >= 2) {
                    valTrim := SubStr(valTrim, 2, StrLen(valTrim) - 2)
                }
                SiruriList.Push(DecodeEscapes(valTrim))
            } else if (kLower = "rareunic" || kLower = "rarechars") {
                valTrim := Trim(val, " `t")
                if (SubStr(valTrim, 1, 1) == '"' && SubStr(valTrim, -1) == '"' && StrLen(valTrim) >= 2) {
                    valTrim := SubStr(valTrim, 2, StrLen(valTrim) - 2)
                }
                decoded := DecodeEscapes(valTrim)
                Global RareUnic .= decoded

                lineClusters := ExtrageGraphemeClusters(decoded)
                maxLineClusters := 36
                if (lineClusters.Length <= maxLineClusters) {
                    RareUnicLines.Push(decoded)
                } else {
                    chunk := ""
                    count := 0
                    for c in lineClusters {
                        chunk .= c
                        count++
                        if (count >= maxLineClusters) {
                            RareUnicLines.Push(chunk)
                            chunk := ""
                            count := 0
                        }
                    }
                    if (chunk != "")
                        RareUnicLines.Push(chunk)
                }
            }
        }
    }

    ExpandedItems := []

    helpTokens := StrSplit(CombHelp, " ")
    if (helpTokens.Length >= 2) {
        actHelp := helpTokens.RemoveAt(1)
        decodedHelpKeys := []
        for k in helpTokens {
            decodedHelpKeys.Push(DecodeEscapes(k))
        }
        for actCode in ExpandActivator(actHelp) {
            ExpandedItems.Push({
                Act: actCode,
                Keys: decodedHelpKeys,
                SeqStr: FormatArrayKeys(decodedHelpKeys),
                Val: ACTION_HELP,
                DisplayVal: "[Fereastră Ajutor]",
                LineNum: 0,
                RawLine: "CombHelp = " CombHelp
            })
        }
    }

    siruriTokens := StrSplit(CombSiruri, " ")
    if (siruriTokens.Length >= 2) {
        actSiruri := siruriTokens.RemoveAt(1)
        decodedSiruriKeys := []
        for k in siruriTokens {
            decodedSiruriKeys.Push(DecodeEscapes(k))
        }
        for actCode in ExpandActivator(actSiruri) {
            ExpandedItems.Push({
                Act: actCode,
                Keys: decodedSiruriKeys,
                SeqStr: FormatArrayKeys(decodedSiruriKeys),
                Val: ACTION_SIRURI,
                DisplayVal: "[Fereastră Șiruri]",
                LineNum: 0,
                RawLine: "CombSiruri = " CombSiruri
            })
        }
    }

    mltSirTokens := StrSplit(CombMltSir, " ")
    if (mltSirTokens.Length >= 2) {
        actMlt := mltSirTokens.RemoveAt(1)
        decodedMltKeys := []
        for k in mltSirTokens {
            decodedMltKeys.Push(DecodeEscapes(k))
        }
        for actCode in ExpandActivator(actMlt) {
            ExpandedItems.Push({
                Act: actCode,
                Keys: decodedMltKeys,
                SeqStr: FormatArrayKeys(decodedMltKeys),
                Val: ACTION_MULSIR,
                DisplayVal: "[Fereastră MulSir]",
                LineNum: 0,
                RawLine: "CombMltSir = " CombMltSir
            })
        }
    }

    rareTokens := StrSplit(CombRareUnic, " ")
    if (rareTokens.Length >= 2) {
        actRare := rareTokens.RemoveAt(1)
        decodedRareKeys := []
        for k in rareTokens {
            decodedRareKeys.Push(DecodeEscapes(k))
        }
        for actCode in ExpandActivator(actRare) {
            ExpandedItems.Push({
                Act: actCode,
                Keys: decodedRareKeys,
                SeqStr: FormatArrayKeys(decodedRareKeys),
                Val: ACTION_RARE,
                DisplayVal: "[Panou Caractere Rare]",
                LineNum: 0,
                RawLine: "CombRareUnic = " CombRareUnic
            })
        }
    }

    for m in RawMappings {
        acts := ExpandActivator(m.RawAct)
        if (acts.Length == 0)
            continue

        for actCode in acts {
            ExpandedItems.Push({
                Act: actCode,
                Keys: m.Keys,
                SeqStr: FormatArrayKeys(m.Keys),
                Val: m.Val,
                DisplayVal: m.Val,
                LineNum: m.LineNum,
                RawLine: m.RawLine
            })
        }
    }

    ; --- Validare 1: Redefiniri ---
    SeenMap := Map()

    for item in ExpandedItems {
        mapKey := item.Act . " " . item.SeqStr
        if SeenMap.Has(mapKey) {
            prevItem := SeenMap[mapKey]
            
            line1Str := (prevItem.LineNum > 0) ? (Format(T("CFG_ERR_LINE_FMT"), prevItem.LineNum, prevItem.RawLine)) : prevItem.RawLine
            line2Str := (item.LineNum > 0) ? (Format(T("CFG_ERR_LINE_FMT"), item.LineNum, item.RawLine)) : item.RawLine

            MesajEroare := T("CFG_ERR_REDEF_HDR") . NumeActivatorDetaliat(item.Act) . " " . item.SeqStr . "`n`n"
            MesajEroare .= T("CFG_ERR_REDEF_LINES") . "`n"
            MesajEroare .= "• " . line1Str . "`n"
            MesajEroare .= "• " . line2Str . "`n`n"
            MesajEroare .= T("CFG_ERR_REDEF_STOP")

            MsgBox(MesajEroare, T("CFG_ERR_REDEF_TITLE"), "Iconx 0x40000")
            ExitApp()
        }
        SeenMap[mapKey] := item
    }

    ; --- Validare 2: Ambiguități ---
    ActGroups := Map()
    for item in ExpandedItems {
        if !ActGroups.Has(item.Act)
            ActGroups[item.Act] := []
        ActGroups[item.Act].Push(item)
    }

    for actCode, itemsList in ActGroups {
        lenCount := itemsList.Length
        Loop lenCount {
            i := A_Index
            item1 := itemsList[i]
            Loop lenCount {
                j := A_Index
                if (i == j)
                    continue
                item2 := itemsList[j]

                if IsPrefixArray(item1.Keys, item2.Keys) {
                    line1Str := (item1.LineNum > 0) ? (Format(T("CFG_ERR_LINE_FMT"), item1.LineNum, item1.RawLine)) : item1.RawLine
                    line2Str := (item2.LineNum > 0) ? (Format(T("CFG_ERR_LINE_FMT"), item2.LineNum, item2.RawLine)) : item2.RawLine

                    MesajEroare := T("CFG_ERR_AMBIG_HDR")
                    MesajEroare .= Format(T("CFG_ERR_AMBIG_PREFIX"), item1.SeqStr, item2.SeqStr, NumeActivatorDetaliat(actCode))
                    MesajEroare .= T("CFG_ERR_AMBIG_LINES") . "`n"
                    MesajEroare .= "• " . line1Str . "`n"
                    MesajEroare .= "• " . line2Str . "`n`n"
                    MesajEroare .= T("CFG_ERR_AMBIG_STOP")

                    MsgBox(MesajEroare, T("CFG_ERR_AMBIG_TITLE"), "Iconx 0x40000")
                    ExitApp()
                }
            }
        }
    }

    Global Mapari := Map()
    for item in ExpandedItems {
        if !Mapari.Has(item.Act)
            Mapari[item.Act] := Map()
        
        Mapari[item.Act][item.SeqStr] := {
            Val: item.Val,
            Keys: item.Keys,
            DisplayVal: item.DisplayVal,
            LineNum: item.LineNum,
            RawLine: item.RawLine
        }
    }
}

FormatArrayKeys(arrKeys) {
    str := ""
    for k in arrKeys
        str .= (A_Index == 1 ? "" : " ") . k
    return str
}

; ==============================================================================
; Engine Interceptare Secvențe (InputHook)
; ==============================================================================

OnActivatorUp(actCode, keyName) {
    if (FerestreDeschise)
        return
    if (A_PriorKey != keyName && A_PriorKey != GetKeyName(keyName))
        return

    PornesteInputHook(actCode)
}

PornesteInputHook(actCode) {
    if !Mapari.Has(actCode)
        return

    actMap := Mapari[actCode]

    maxKeysLen := 0
    for seqStr, info in actMap {
        if (info.Keys.Length > maxKeysLen)
            maxKeysLen := info.Keys.Length
    }

    if (maxKeysLen == 0)
        return

    ih := InputHook("L" maxKeysLen, "{Esc}")

    CheckSequence(hook, char) {
        inputTyped := String(hook.Input)
        inputKeys := StrSplit(inputTyped)

        isMatch := false
        isPrefix := false
        matchedInfo := ""

        for seqStr, info in actMap {
            if (info.Keys.Length == inputKeys.Length && ArrayEquals(info.Keys, inputKeys)) {
                isMatch := true
                matchedInfo := info
            } else if IsPrefixArray(inputKeys, info.Keys) {
                isPrefix := true
            }
        }

        if (isMatch && !isPrefix) {
            hook.Stop()
        } else if (!isMatch && !isPrefix) {
            hook.Stop()
        }
    }

    ih.OnChar := CheckSequence

    ih.Start()

    if (TimpSec > 0)
        ih.Wait(TimpSec)
    else
        ih.Wait()

    if (ih.EndReason = "EndKey")
        return

    inputTyped := String(ih.Input)
    if (inputTyped == "")
        return

    inputKeys := StrSplit(inputTyped)

    matchedInfo := ""
    for seqStr, info in actMap {
        if (info.Keys.Length == inputKeys.Length && ArrayEquals(info.Keys, inputKeys)) {
            matchedInfo := info
            break
        }
    }

    if (matchedInfo != "") {
        if (matchedInfo.Val == ACTION_HELP) {
            ArataAjutor()
        } else if (matchedInfo.Val == ACTION_RARE) {
            ArataPanouRareUnic()
        } else if (matchedInfo.Val == ACTION_SIRURI) {
            ArataPanouSiruri()
        } else if (matchedInfo.Val == ACTION_MULSIR) {
            ArataPanouMulSir()
        } else {
            TrimiteTextValoare(matchedInfo.Val)
        }
    } else {
        SendText(inputTyped)
    }
}

ArrayEquals(arr1, arr2) {
    if (arr1.Length != arr2.Length)
        return false
    for idx, val in arr1 {
        if (arr2[idx] != val)
            return false
    }
    return true
}

TrimiteTextValoare(valoare) {
    if InStr(valoare, "\cb") {
        textCB := A_Clipboard
        valoare := StrReplace(valoare, "\cb", textCB)
    }
    if (valoare != "") {
        SendText(valoare)
    }
}

; ==============================================================================
; Interfețe Grafice (GUI) cu Limită 3/4 din Ecran și Scroll Automat
; ==============================================================================

; --- 1. Fereastra de Ajutor ---
ArataAjutor() {
    Global FerestreDeschise := true, FereastraCurenta
    
    dpiScale := A_ScreenDPI / 96.0
    maxW := Integer((A_ScreenWidth * 0.75) / dpiScale)
    maxH := Integer((A_ScreenHeight * 0.75) / dpiScale)

    HelpGui := Gui("+Resize +MinSize400x300 +MaxSize" maxW "x" maxH, T("HELP_TITLE"))
    Global FereastraCurenta := HelpGui
    HelpGui.SetFont("s" DimFont, "Consolas")

    lang := ObtineLimbaCurenta()
    lblLang := (lang == "ro") ? "Limba" : ((lang == "de") ? "Sprache" : "Language")
    valLang := (Limba != "") ? Limba : (lang . ((lang == "ro") ? " (Detectat automat)" : ((lang == "de") ? " (Automatisch erkannt)" : " (Auto-detected)")))

    lblTimp := (lang == "ro") ? "TimpSec" : "TimeoutSec"
    lblDimFont := (lang == "ro") ? "DimFont" : "FontSize"
    lblDimFontRare := (lang == "ro") ? "DimFontRare" : "RareFontSize"
    lblCombHelp := "CombHelp"
    lblCombRare := (lang == "ro") ? "CombRareUnic" : "CombRareChars"
    lblCombSiruri := (lang == "ro") ? "CombSiruri" : "CombStrings"
    lblCombMltSir := (lang == "ro") ? "CombMltSir" : "CombMultiStrings"
    lblRare := (lang == "ro") ? "RareUnic" : "RareChars"
    lblSiruri := (lang == "ro") ? "Siruri" : "Strings"

    VarPairs := [
        [lblLang, valLang],
        [lblTimp, String(TimpSec)],
        [lblDimFont, String(DimFont)],
        [lblDimFontRare, String(DimFontRare)],
        [lblCombHelp, CombHelp],
        [lblCombRare, CombRareUnic],
        [lblCombSiruri, CombSiruri],
        [lblCombMltSir, CombMltSir]
    ]
    if (RareUnicLines.Length > 0) {
        for idx, rLine in RareUnicLines {
            VarPairs.Push([lblRare, '"' rLine '"'])
        }
    } else if (RareUnic != "") {
        VarPairs.Push([lblRare, '"' RareUnic '"'])
    }
    for idx, s in SiruriList {
        VarPairs.Push([lblSiruri, '"' s '"'])
    }

    maxKeyLen := 0
    for pair in VarPairs {
        if (StrLen(pair[1]) > maxKeyLen)
            maxKeyLen := StrLen(pair[1])
    }

    FullText := T("HELP_VARS_HDR") . "`n`n"
    for pair in VarPairs {
        FullText .= PadRight(pair[1], maxKeyLen + 2) . "= " . pair[2] . "`n"
    }

    FullText .= "`n" . T("HELP_MAPS_HDR") . "`n`n"

    FlatList := []
    maxSeqLen := 0

    for actCode, actMap in Mapari {
        actName := NumeActivatorDetaliat(actCode)
        for seqStr, info in actMap {
            fullSeq := actName . " " . seqStr
            if (StrLen(fullSeq) > maxSeqLen)
                maxSeqLen := StrLen(fullSeq)

            displayVal := info.DisplayVal
            if (info.Val == ACTION_HELP) {
                displayVal := T("HELP_ACTION_HELP")
            } else if (info.Val == ACTION_RARE) {
                displayVal := T("HELP_ACTION_RARE")
            } else if (info.Val == ACTION_SIRURI) {
                displayVal := T("HELP_ACTION_SIRURI")
            } else if (info.Val == ACTION_MULSIR) {
                displayVal := T("HELP_ACTION_MULSIR")
            } else {
                if (InStr(displayVal, " ") || InStr(displayVal, "`n") || InStr(displayVal, "`r") || displayVal == "")
                    displayVal := '"' . displayVal . '"'
            }

            FlatList.Push({
                FullSeq: fullSeq,
                DisplayVal: displayVal
            })
        }
    }

    Loop FlatList.Length {
        i := A_Index
        Loop FlatList.Length - i {
            j := A_Index
            if (StrCompare(FlatList[j].FullSeq, FlatList[j+1].FullSeq) > 0) {
                tmp := FlatList[j]
                FlatList[j] := FlatList[j+1]
                FlatList[j+1] := tmp
            }
        }
    }

    for item in FlatList {
        FullText .= PadRight(item.FullSeq, maxSeqLen + 2) . "-> " . item.DisplayVal . "`n"
    }

    editW := Min(720, maxW - 40)
    lineHeight := Integer(DimFont * 1.5)
    maxLines := Max(5, (maxH - 120) // lineHeight)
    linesToShow := Min(22, maxLines)

    EditCtrl := HelpGui.Add("Edit", "w" editW " r" linesToShow " ReadOnly VScroll HScroll", FullText)
    BtnClose := HelpGui.Add("Button", "w120 Default", T("BTN_CLOSE"))

    BtnClose.OnEvent("Click", (*) => InchideFereastraActiva())
    HelpGui.OnEvent("Close", (*) => InchideFereastraActiva())
    HelpGui.OnEvent("Escape", (*) => InchideFereastraActiva())

    HelpGui.Show("AutoSize Center")
    BtnClose.Focus()
}

; --- 2. Panoul Șiruri ---
ArataPanouSiruri() {
    if (SiruriList.Length == 0) {
        MsgBox(T("SIRURI_EMPTY"), "AllCharsAHK", "Iconi 0x40000")
        return
    }

    Global TargetHwnd := WinExist("A")
    Global FerestreDeschise := true, FereastraCurenta

    dpiScale := A_ScreenDPI / 96.0
    maxW := Integer((A_ScreenWidth * 0.75) / dpiScale)
    maxH := Integer((A_ScreenHeight * 0.75) / dpiScale)

    maxStrLen := 10
    for s in SiruriList {
        if (StrLen(s) > maxStrLen)
            maxStrLen := StrLen(s)
    }

    charW := DimFont * 0.75
    neededBtnW := Max(Integer(maxStrLen * charW + DimFont * 2), 260)
    btnH := Integer(DimFont * 2.2)
    spacing := 4

    contentW := neededBtnW + 24
    contentH := 24 + SiruriList.Length * (btnH + spacing) - spacing

    needsV := (contentH > maxH)
    needsH := (contentW > maxW)

    guiOpts := "+AlwaysOnTop +ToolWindow -MinimizeBox -MaximizeBox"
    if (needsV)
        guiOpts .= " +0x200000"
    if (needsH)
        guiOpts .= " +0x100000"

    SiruriGui := Gui(guiOpts, T("SIRURI_TITLE"))
    Global FereastraCurenta := SiruriGui
    SiruriGui.SetFont("s" . DimFont, "Consolas")

    btnW := needsH ? neededBtnW : (Min(contentW, maxW) - 24)

    for idx, s in SiruriList {
        posX := 12
        posY := 12 + (idx - 1) * (btnH + spacing)
        optsStr := Format("x{} y{} w{} h{}", posX, posY, btnW, btnH)
        btn := SiruriGui.Add("Button", optsStr, s)
        btn.OnEvent("Click", InseraSirClick.Bind(s))
    }

    InseraSirClick(strToSend, *) {
        if (TargetHwnd) {
            try WinActivate("ahk_id " TargetHwnd)
            try WinWaitActive("ahk_id " TargetHwnd, , 0.5)
        }
        TrimiteTextValoare(strToSend)
    }

    SiruriGui.OnEvent("Close", (*) => InchideFereastraActiva())
    SiruriGui.OnEvent("Escape", (*) => InchideFereastraActiva())

    dispW := Min(contentW, maxW)
    dispH := Min(contentH, maxH)

    SiruriGui.Show(Format("w{} h{} Center", dispW, dispH))

    AutoScroller.Setup(SiruriGui, contentW, contentH)
}

; --- 3. Panoul Caractere Rare ---
ArataPanouRareUnic() {
    if (RareUnic == "") {
        MsgBox(T("RARE_EMPTY"), "AllCharsAHK", "Iconi 0x40000")
        return
    }

    Global TargetHwnd := WinExist("A")
    Global FerestreDeschise := true, FereastraCurenta

    clusters := ExtrageGraphemeClusters(RareUnic)
    if (clusters.Length == 0) {
        Global FerestreDeschise := false
        return
    }

    dpiScale := A_ScreenDPI / 96.0
    maxW := Integer((A_ScreenWidth * 0.75) / dpiScale)
    maxH := Integer((A_ScreenHeight * 0.75) / dpiScale)

    btnW := Max(Integer(DimFontRare * 2.6), 42)
    btnH := btnW
    spacing := 6

    maxColsFit := Max(1, (maxW - 24) // (btnW + spacing))
    cols := Min(clusters.Length, Min(8, maxColsFit))
    if (cols < 1)
        cols := 1

    rows := Ceil(clusters.Length / cols)

    contentW := 24 + cols * (btnW + spacing) - spacing
    contentH := 24 + rows * (btnH + spacing) - spacing

    if (contentH > maxH && cols < maxColsFit) {
        cols := Min(clusters.Length, maxColsFit)
        rows := Ceil(clusters.Length / cols)
        contentW := 24 + cols * (btnW + spacing) - spacing
        contentH := 24 + rows * (btnH + spacing) - spacing
    }

    needsV := (contentH > maxH)
    needsH := (contentW > maxW)

    guiOpts := "+AlwaysOnTop +ToolWindow -MinimizeBox -MaximizeBox"
    if (needsV)
        guiOpts .= " +0x200000"
    if (needsH)
        guiOpts .= " +0x100000"

    RareGui := Gui(guiOpts, T("RARE_TITLE"))
    Global FereastraCurenta := RareGui
    RareGui.SetFont("s" . DimFontRare, "Segoe UI Emoji")

    for idx, char in clusters {
        colIdx := Mod(idx - 1, cols)
        rowIdx := (idx - 1) // cols

        posX := 12 + colIdx * (btnW + spacing)
        posY := 12 + rowIdx * (btnH + spacing)

        optStr := Format("x{} y{} w{} h{}", posX, posY, btnW, btnH)
        btn := RareGui.Add("Button", optStr, char)
        btn.OnEvent("Click", TrimiteCaracter.Bind(char))
    }

    TrimiteCaracter(charToSend, *) {
        if (TargetHwnd) {
            try WinActivate("ahk_id " TargetHwnd)
            try WinWaitActive("ahk_id " TargetHwnd, , 0.5)
        }
        SendText(charToSend)
    }

    RareGui.OnEvent("Close", (*) => InchideFereastraActiva())
    RareGui.OnEvent("Escape", (*) => InchideFereastraActiva())

    dispW := Min(contentW, maxW)
    dispH := Min(contentH, maxH)

    RareGui.Show(Format("w{} h{} Center", dispW, dispH))

    AutoScroller.Setup(RareGui, contentW, contentH)
}

; --- 4. Fereastra MulSir ---
ArataPanouMulSir() {
    Global TargetHwnd := WinExist("A")
    Global FerestreDeschise := true, FereastraCurenta

    dpiScale := A_ScreenDPI / 96.0
    maxW := Integer((A_ScreenWidth * 0.75) / dpiScale)
    maxH := Integer((A_ScreenHeight * 0.75) / dpiScale)

    ctrlH := Max(28, Integer(DimFont * 1.8))
    spacing := 6

    wLblSursa := Max(110, Integer(DimFont * 7.0))
    wEditSursa := Max(160, Integer(DimFont * 10.0))
    wLblMul := Max(30, Integer(DimFont * 1.8))
    wEditRep := Max(50, Integer(DimFont * 3.5))
    wBtnGen := Max(95, Integer(DimFont * 6.0))

    totalRow1W := wLblSursa + spacing + wEditSursa + spacing + wLblMul + spacing + wEditRep + spacing + wBtnGen

    clusters := (RareUnic != "") ? ExtrageGraphemeClusters(RareUnic) : []
    rareBtnW := Max(Integer(DimFontRare * 2.6), 42)
    rareBtnH := rareBtnW

    maxColsFit := Max(1, (maxW - 24) // (rareBtnW + spacing))
    cols := (clusters.Length > 0) ? Min(clusters.Length, Max(8, (totalRow1W - 24) // (rareBtnW + spacing))) : 1
    if (cols < 1)
        cols := 1
    if (cols > maxColsFit)
        cols := maxColsFit

    rows := (clusters.Length > 0) ? Ceil(clusters.Length / cols) : 0

    matrixW := (clusters.Length > 0) ? (cols * (rareBtnW + spacing) - spacing) : 0
    matrixH := (rows > 0) ? (rows * (rareBtnH + spacing) - spacing + 8) : 0

    headerH := 12 + ctrlH + spacing + ctrlH + 16
    vScrollW := SysGet(2) ; latime scrollbar vertical

    maxChildH := maxH - headerH - 12
    needsChildV := (matrixH > maxChildH)

    childW := matrixW + (needsChildV ? vScrollW : 0)
    neededW := Max(totalRow1W, childW)

    contentW := 24 + neededW
    childH := Min(matrixH, maxChildH)
    totalH := headerH + (rows > 0 ? (childH + 12) : 0)

    guiOpts := "+AlwaysOnTop +ToolWindow -MinimizeBox -MaximizeBox"
    MulSirGui := Gui(guiOpts, T("MULSIR_TITLE"))
    Global FereastraCurenta := MulSirGui

    ; Rândul 1 (Celula 1) - Fix
    MulSirGui.SetFont("s" . DimFont, "Segoe UI")

    curY := 12
    curX := 12

    MulSirGui.Add("Text", Format("x{} y{} w{} h{} +0x200", curX, curY, wLblSursa, ctrlH), T("MULSIR_LBL_SRC"))
    curX += wLblSursa + spacing

    EditSursa := MulSirGui.Add("Edit", Format("x{} y{} w{} h{}", curX, curY, wEditSursa, ctrlH), "")
    curX += wEditSursa + spacing

    MulSirGui.Add("Text", Format("x{} y{} w{} h{} +0x200 Center", curX, curY, wLblMul, ctrlH), "×")
    curX += wLblMul + spacing

    EditRepetari := MulSirGui.Add("Edit", Format("x{} y{} w{} h{} Number Limit3", curX, curY, wEditRep, ctrlH), "")
    curX += wEditRep + spacing

    BtnGenerare := MulSirGui.Add("Button", Format("x{} y{} w{} h{}", curX, curY, wBtnGen, ctrlH), T("MULSIR_BTN_GEN"))

    ; Rândul 2 (Celula 2) - Fix
    curY += ctrlH + spacing
    curX := 12

    MulSirGui.Add("Text", Format("x{} y{} w{} h{} +0x200", curX, curY, wLblSursa, ctrlH), T("MULSIR_LBL_RES"))
    curX += wLblSursa + spacing

    btnTrimiteX := 12 + totalRow1W - wBtnGen
    wEditRez := btnTrimiteX - spacing - curX

    EditRezultat := MulSirGui.Add("Edit", Format("x{} y{} w{} h{}", curX, curY, wEditRez, ctrlH), "")

    BtnTrimite := MulSirGui.Add("Button", Format("x{} y{} w{} h{}", btnTrimiteX, curY, wBtnGen, ctrlH), T("MULSIR_BTN_SEND"))

    lastFocusedEdit := EditRezultat
    EditSursa.OnEvent("Focus", (*) => (lastFocusedEdit := EditSursa))
    EditRezultat.OnEvent("Focus", (*) => (lastFocusedEdit := EditRezultat))

    InsereazaTextLaCursor(ctrl, textToInsert) {
        if (!ctrl || !ctrl.Hwnd)
            return
        SendMessage(0x00C2, 1, StrPtr(textToInsert), ctrl.Hwnd)
        ctrl.Focus()
    }

    GenerareClick(*) {
        repStr := Trim(EditRepetari.Value)
        if (repStr == "" || !IsInteger(repStr) || Integer(repStr) <= 0) {
            MsgBox(T("MULSIR_ERR_COUNT"), T("MULSIR_ERR_TITLE"), "Icon! 0x40000")
            EditRepetari.Focus()
            return
        }
        n := Integer(repStr)
        src := DecodeMulSirEscapes(EditSursa.Value)
        rez := ""
        Loop n {
            rez .= src
        }
        InsereazaTextLaCursor(EditRezultat, rez)
    }

    TrimiteClick(*) {
        textDeTrimis := EditRezultat.Value
        if (TargetHwnd) {
            try WinActivate("ahk_id " TargetHwnd)
            try WinWaitActive("ahk_id " TargetHwnd, , 0.5)
        }
        TrimiteTextValoare(textDeTrimis)
    }

    BtnGenerare.OnEvent("Click", GenerareClick)
    BtnTrimite.OnEvent("Click", TrimiteClick)

    ; Rândul 3 - Container Copil Scrollabil pentru Caractere Rare
    RareContainer := ""
    if (clusters.Length > 0) {
        childOpts := "+Parent" . MulSirGui.Hwnd . " -Caption +ToolWindow"
        if (needsChildV)
            childOpts .= " +0x200000"

        RareContainer := Gui(childOpts)
        RareContainer.SetFont("s" . DimFontRare, "Segoe UI Emoji")

        for idx, char in clusters {
            colIdx := Mod(idx - 1, cols)
            rowIdx := (idx - 1) // cols

            posX := colIdx * (rareBtnW + spacing)
            posY := rowIdx * (rareBtnH + spacing)

            optStr := Format("x{} y{} w{} h{}", posX, posY, rareBtnW, rareBtnH)
            btn := RareContainer.Add("Button", optStr, char)
            btn.OnEvent("Click", InseraRareClick.Bind(char))
        }

        InseraRareClick(charToSend, *) {
            InsereazaTextLaCursor(lastFocusedEdit, charToSend)
        }
    }

    HandleMulSirEnter(*) {
        fHwnd := DllCall("GetFocus", "Ptr")
        if (fHwnd == EditRepetari.Hwnd) {
            GenerareClick()
        } else if (fHwnd == EditSursa.Hwnd) {
            EditRepetari.Focus()
        } else {
            TrimiteClick()
        }
    }

    HotIfWinActive("ahk_id " MulSirGui.Hwnd)
    Hotkey("Enter", HandleMulSirEnter, "On")

    InchideMulSir(*) {
        try {
            HotIfWinActive("ahk_id " MulSirGui.Hwnd)
            Hotkey("Enter", "Off")
        }
        if (RareContainer) {
            try AutoScroller.Cleanup(RareContainer.Hwnd)
            try RareContainer.Destroy()
            RareContainer := ""
        }
        InchideFereastraActiva()
    }

    MulSirGui.OnEvent("Close", InchideMulSir)
    MulSirGui.OnEvent("Escape", InchideMulSir)

    dispW := Min(contentW, maxW)
    dispH := Min(totalH, maxH)

    MulSirGui.Show(Format("w{} h{} Center", dispW, dispH))
    if (RareContainer) {
        ; Masuram baza reala a randului 2 in coordonate client ale parintelui pentru a evita orice suprapunere
        rEdit := Buffer(16, 0)
        DllCall("GetWindowRect", "Ptr", EditRezultat.Hwnd, "Ptr", rEdit)
        rBtn := Buffer(16, 0)
        DllCall("GetWindowRect", "Ptr", BtnTrimite.Hwnd, "Ptr", rBtn)
        maxBottomScreen := Max(NumGet(rEdit, 12, "Int"), NumGet(rBtn, 12, "Int"))

        pt := Buffer(8, 0)
        NumPut("Int", 0, pt, 0)
        NumPut("Int", maxBottomScreen, pt, 4)
        DllCall("ScreenToClient", "Ptr", MulSirGui.Hwnd, "Ptr", pt)
        row2BottomClient := NumGet(pt, 4, "Int")

        childPosY := row2BottomClient + 10
        childPosX := 12 + ((neededW - childW) // 2)
        RareContainer.Show(Format("x{} y{} w{} h{}", childPosX, childPosY, childW, childH))
        AutoScroller.Setup(RareContainer, matrixW, matrixH, MulSirGui.Hwnd)
    }
    EditSursa.Focus()
}
; ==============================================================================
; Înregistrare Hotkeys (Taste Activator)
; ==============================================================================

InregistreazaHotkeys() {
    HotIf (*) => !FerestreDeschise

    Hotkey("~LCtrl Up", (*) => OnActivatorUp("lc", "LCtrl"))
    Hotkey("~RCtrl Up", (*) => OnActivatorUp("rc", "RCtrl"))
    Hotkey("~LShift Up", (*) => OnActivatorUp("ls", "LShift"))
    Hotkey("~RShift Up", (*) => OnActivatorUp("rs", "RShift"))
    Hotkey("~LAlt Up", (*) => OnActivatorUp("la", "LAlt"))
    Hotkey("~RAlt Up", (*) => OnActivatorUp("ra", "RAlt"))

    HotIf (*) => FerestreDeschise
    Hotkey("Escape", (*) => InchideFereastraActiva())
}

; ==============================================================================
; Punct de Intrare (Execution Flow)
; ==============================================================================

IncarcaSiValideazaConfig()
ConfigureazaTrayMenu()
InregistreazaHotkeys()