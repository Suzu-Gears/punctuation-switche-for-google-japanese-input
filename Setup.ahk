#Requires AutoHotkey v1.1.33
#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

; protoc.zipをダウンロード
protocZipURL := "https://github.com/protocolbuffers/protobuf/releases/download/v26.1/protoc-26.1-win64.zip"
protocZipPath := A_ScriptDir "\protoc.zip"
UrlDownloadToFile, %protocZipURL%, %protocZipPath%
if (ErrorLevel) {
    MsgBox, 16, ダウンロード失敗, protoc.zip のダウンロードに失敗しました。
    ExitApp
}

; protoc.zipを解凍
RunWait, powershell -command "Expand-Archive -Path 'protoc.zip' -DestinationPath 'protoc' -Force", , Hide
; protoc.zipを削除
FileDelete, protoc.zip

; config.protoをダウンロード
targetFolder := A_ScriptDir "\protoc\bin"
configProtoURL := "https://raw.githubusercontent.com/google/mozc/master/src/protocol/config.proto"
configProtoPath := targetFolder "\config.proto"
UrlDownloadToFile, %configProtoURL%, %configProtoPath%
if (ErrorLevel) {
    MsgBox, 16, ダウンロード失敗, config.proto のダウンロードに失敗しました。
    ExitApp
}

MsgBox, , 成功, 句読点スイッチャーのセットアップが完了しました。
