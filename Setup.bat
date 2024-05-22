@echo off
setlocal

rem 作業ディレクトリをスクリプトのある場所に設定
cd /d %‾dp0

rem protoc.zipをダウンロード
set protocZipURL=https://github.com/protocolbuffers/protobuf/releases/download/v26.1/protoc-26.1-win64.zip
set protocZipPath=protoc.zip

powershell -NoLogo -Command "Invoke-WebRequest -Uri '%protocZipURL%' -OutFile '%protocZipPath%' -ErrorAction Stop"
if %ERRORLEVEL% neq 0 (
    echo ダウンロード失敗: protoc.zip のダウンロードに失敗しました。
    pause
    exit /b 1
)
echo protoc.zip のダウンロードに成功。

rem protoc.zipを解凍
powershell -NoLogo -Command "Expand-Archive -Path '%protocZipPath%' -DestinationPath 'protoc' -Force -ErrorAction Stop"
if %ERRORLEVEL% neq 0 (
    echo 解凍失敗: protoc.zip の解凍に失敗しました。
    pause
    exit /b 1
)
echo protoc.zip の解凍に成功。

rem protoc.zipを削除
del /f protoc.zip

rem config.protoをダウンロード
set targetFolder=protoc¥bin
set configProtoURL=https://raw.githubusercontent.com/google/mozc/master/src/protocol/config.proto
set configProtoPath=%targetFolder%¥config.proto

powershell -NoLogo -Command "Invoke-WebRequest -Uri '%configProtoURL%' -OutFile '%configProtoPath%' -ErrorAction Stop"
if %ERRORLEVEL% neq 0 (
    echo ダウンロード失敗: config.proto のダウンロードに失敗しました。
    pause
    exit /b 1
)
echo config.proto のダウンロードに成功。

echo 句読点スイッチャーのセットアップが完了しました。
pause
exit /b 0
