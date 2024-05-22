#Requires AutoHotkey v1.1.33
#NoEnv
#SingleInstance, Force
SendMode Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir% ; 現在のワークディレクトリにスクリプトのディレクトリを指定
EnvGet, AppDataPath, Appdata ; 環境変数からAppDataを取得

; Google日本語入力の設定ファイルのパスは下記
; C:\Users\%username%\AppData\LocalLow\Google\Google Japanese Input
; AppDataPathで取得したPathにはRomingまで含まれるので"AppData"の後の文字列を削除する
newPath := RegExReplace(AppDataPath, "\\AppData.*$", "\AppData")
global basePath := newPath . "\LocalLow\Google\Google Japanese Input\"

; protoc.exe と config.proto ファイルへのパスを指定
global ProtocPath := "protoc\bin\protoc.exe"
global ConfigProtoPath := "protoc\bin\config.proto"
global ConfigDbPath := BasePath . "config1.db"
global TextProtoPath := "protoc\bin\config1.txt"

global CurrentMode
global ConfigText

global isRunning := false ; 切替処理の実行中を示すフラグ

if (!FileExist(ProtocPath)) {
    MsgBox, 16, エラー, protoc\bin\protoc.exeが見つかりません。`nSetup.exeを実行してください。
    ExitApp
}
if (!FileExist(ConfigProtoPath)) {
    MsgBox, 16, エラー, protoc\bin\config.protoが見つかりません。`nSetup.exeを実行してください。
    ExitApp
}

; スクリプト起動時に現在のモードに合わせてアイコンを設定(ConfigTextとCurrentModeに現在の状態が入る)
SetInitialIcon()

; タスクトレイのアイコンがクリックされた場合の処理
OnMessage(0x404, "AHK_NOTIFYICON")

; タスクトレイメニューの設定
Menu, Tray, NoStandard
Menu, Tray, Add, ショートカットキーの有効化, ToggleHotkeyEnabled
Menu, Tray, Add, ショートカットキーの設定, ShowGUI
Menu, Tray, Add, 終了, ExitScript

; 可変ショートカットキーの処理(参照: https://www.autohotkey.com/boards/viewtopic.php?style=1&f=76&t=43450&sid=a28ce74e2b7c9514c291ae1613e12a93)
global iniFile := A_ScriptDir . "/config.ini" ; INIファイルのパス設定
global savedValue
global newValue
global HotkeyEnabled
modifiers := {"Alt": "!", "Ctrl": "^", "Shift": "+"} ; 各キー名に対応するシンボルを持つ連想配列
Gui, +hwndGUIID ; 新しいGUIを作成し、その一意なID（別名 hWnd）を'GUIID'に格納
AHKID := "ahk_id " . GUIID ; 'ahk_id'の値を取得するためのショートカットを作成 (参照: https://www.autohotkey.com/docs/misc/WinTitle.htm)
IniRead, HotkeyEnabled, % iniFile, hotkey, HotkeyEnabled, 1 ; iniファイルからショートカットキーの有効/無効の設定を読み込む
IniRead, newValue, % iniFile, hotkey, key, %A_Space% ; INIファイルからホットキーの保存値を読み込み デフォルト値は半角スペース
IniRead, UseDefaultShortcut, % iniFile, hotkey, UseDefaultShortcut, 1 ; iniファイルからデフォルトのショートカットキー(Ctrl + Shift)を使うかどうかの保存値を読み込み
if (!FileExist(iniFile)) {
    ; iniファイルがなければ作成
    SaveHotkey()
    IniWrite, % HotkeyEnabled, % iniFile, hotkey, HotkeyEnabled ; ショートカットキーの有効/無効の状態を保存
    IniWrite, % UseDefaultShortcut, % iniFile, hotkey, UseDefaultShortcut
}
SetHotkeyEnabled() ; トレイのチェックマークに反映
SetHotkey() ; ホットキーに反映

Gui, Add, hotkey, vmyHotkeyControl w300, % savedValue ; ホットキー入力コントロールをGUIに追加
Gui, Add, Checkbox, vUseDefaultShortcut gToggleDefaultShortcut, デフォルトのショートカットキー[Crtl+Shift]を使用する
Gui, Add, Button, +Default gSave w80, &Save ; OKボタンをGUIに追加
GuiControl, , UseDefaultShortcut, %UseDefaultShortcut% ; 読み込んだ設定を反映

return ; -----スクリプト起動時に実行する処理ここまで-----

; アプリを終了するコマンド
ExitScript:
ExitApp

; 左クリックはクリック数に関わらず常に句読点スイッチを実行
AHK_NOTIFYICON(wParam, lParam, msg, hwnd) {
    ; msgとhwndはv1からv2への変換時にエラーが出ないように入れる
    ; WM_LBUTTONUP or WM_LBUTTONDBLCLK
    if (lParam = 0x201 || lParam = 0x203) {
        TogglePunctuation()
        return
    }
}

; -----句読点切替の処理-----
SetInitialIcon() {
    GetCurrentMode()
    SetIcon()
}

TogglePunctuation() {
    if (isRunning) { ; 実行中にTogglePunctuation()が呼び出されても切替処理を行わない
        return
    }
    isRunning := true
    GetCurrentMode()
    SwitchConfig()
    SetIcon()
    isRunning := false
}

GetCurrentMode() {
    ; config1.dbをデコード
    command := ComSpec . " /c " . ProtocPath . " --decode=mozc.config.Config " . ConfigProtoPath . " < """ . ConfigDbPath . """ > " . TextProtoPath
    RunWait, %command%, , Hide
    ; config1.txtから現在の設定を読み取る
    FileRead, ConfigText, %TextProtoPath%
    if (ErrorLevel) {
        MsgBox, 16, エラー, config1.txtの読み込みに失敗しました。`nアプリケーションを終了します。
        ExitApp
    }
    ; 現在の句読点設定を判定
    if InStr(ConfigText, "punctuation_method: KUTEN_TOUTEN") {
        CurrentMode := "KUTEN_TOUTEN"
    } else if InStr(ConfigText, "punctuation_method: COMMA_PERIOD") {
        CurrentMode := "COMMA_PERIOD"
    } else {
        MsgBox, 16, エラー, config1.dbから句読点の設定を読み込めませんでした。`nアプリケーションを終了します。
        ExitApp
    }
}

SwitchConfig() {
    if (CurrentMode = "KUTEN_TOUTEN") {
        ; 現在の設定の句点読点をカンマピリオドに置換して新しい設定文字列に格納
        StringReplace, ConfigText, ConfigText, punctuation_method: KUTEN_TOUTEN, punctuation_method: COMMA_PERIOD, All
        CurrentMode := "COMMA_PERIOD"
    } else if (CurrentMode = "COMMA_PERIOD") {
        ; 現在の設定のカンマピリオドを句点読点に置換して新しい設定文字列に格納
        StringReplace, ConfigText, ConfigText, punctuation_method: COMMA_PERIOD, punctuation_method: KUTEN_TOUTEN, All
        CurrentMode := "KUTEN_TOUTEN"
    }
    FileDelete, %TextProtoPath% ; 既存のconfig1.txtを削除
    FileAppend, %ConfigText%, %TextProtoPath% ; 新しい内容でconfig1.txtを作成
    ; config1.textprotoをエンコード
    command := ComSpec . " /c " . ProtocPath . " --encode=mozc.config.Config " . ConfigProtoPath . " < " . TextProtoPath . " > " . """" . ConfigDbPath . """"
    RunWait, %command%, , Hide
    ; GoogleIMEJaConverter.exeプロセスを強制終了
    Run, %ComSpec% /c taskkill /f /im GoogleIMEJaConverter.exe, , Hide
}

SetIcon() {
    Menu, Tray, Icon, % "icons\" . CurrentMode . ".ico"
}
; -----句読点切替の処理ここまで-----

; -----可変ショートカットキーの処理-----
ShowGUI:
    Gui, Show, AutoSize ; GUIを表示する
    GuiControl, Focus, myHotkeyControl ; ホットキー入力コントロールにフォーカスを合わせる
return

#If (GuiControlGetFocus() = "myHotkeyControl") ; GuiControlGetFocusの呼び出しによって返された値が'myHotkeyControl'である場合
    *Space::
    *Escape::
        list := "" ; 空の文字列を初期化
        for name, symbol in modifiers ; オブジェクト内の各キー-値ペアに対してコマンドシリーズを一度実行
        {
            if (GetKeyState(name))
                list .= symbol ; 修飾子が押されている場合（GetKeyState()がこの場合trueを返す）、そのシンボルを文字列に追加
        }
        Sleep, 100 ; ホットキー制御は最初にspaceまたはescapeをキャッチしますが、表示されない場合があります
        KeyWait, Alt ; altは特別なキーであり、最初にリリースする必要があります
        GuiControl, , myHotkeyControl, % list . LTrim(A_ThisHotkey, "*") ; 修飾子（存在する場合）とホットキー自体を連結して、ホットキー制御の新しい値を設定
    return
#If

Save:
    Gui, Submit ; GUIからの入力を受け取る
    if (!UseDefaultShortcut) {
        newValue := myHotkeyControl
    }
    SaveHotkey()
    SetHotkey()
return

SaveHotkey() {
    IniWrite, % newValue, % iniFile, hotkey, key
}

SetHotkey() {
    if (HotkeyEnabled) {
        if (savedValue <> newValue) {
            if (savedValue) {
                Hotkey, %savedValue%, , Off
            }
            if (newValue) {
                Hotkey, %newValue%, VariableHotkey
            }
        }
        savedValue := newValue
    } else {
        if (savedValue) {
            Hotkey, %savedValue%, , Off
        }
    }
}

SetHotkeyEnabled() {
    if (HotkeyEnabled) {
        Menu, Tray, Check, ショートカットキーの有効化
    } else {
        Menu, Tray, Uncheck, ショートカットキーの有効化
    }
}

ToggleHotkeyEnabled:
    HotkeyEnabled := !HotkeyEnabled ; 有効/無効をトグル
    IniWrite, % HotkeyEnabled, % iniFile, hotkey, HotkeyEnabled ; ショートカットキーの有効/無効の状態を保存
    SetHotkeyEnabled() ; トレイのチェックマークに反映
    SetHotkey() ; ホットキーに反映
return

; チェックボックスの状態変更時の処理を追加
ToggleDefaultShortcut:
    Gui, Submit, NoHide
    IniWrite, % UseDefaultShortcut, % iniFile, hotkey, UseDefaultShortcut
    if (UseDefaultShortcut) {
        newValue :=
        SetHotkey()
    } else {
        ; チェック解除時の動作（必要に応じてここに動作を定義）
    }
return

GuiControlGetFocus(whichGUI:=1) {
    GuiControlGet, focusedControl, %whichGUI%:FocusV ; GuiControlGetを見る
    return focusedControl ; 入力フォーカスを持つコントロールの関連変数を返す
}

VariableHotkey:
    TogglePunctuation()
return
; -----可変ショートカットキーの処理ここまで-----

#If ((UseDefaultShortcut == 1) && (HotkeyEnabled == 1))
    ; CtrlとShiftが同時に押された場合に句読点切り替えを実行
    ~Control & ~Shift::
    ~Shift & ~Control::
        TogglePunctuation()
    return
#If
