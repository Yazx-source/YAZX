@echo off
setlocal enabledelayedexpansion

REM Prevent two instances running at once
if exist "%TEMP%\yazx_watcher.lock" exit /b 0
echo running > "%TEMP%\yazx_watcher.lock"

set "H=%WINDIR%\System32\drivers\etc\hosts"
set "TAG=# YAZX-OFFLINE"

REM Check admin rights - request once silently if missing
>"%SystemRoot%\yazx_t.tmp" echo . 2>nul
if not exist "%SystemRoot%\yazx_t.tmp" (
  del "%TEMP%\yazx_watcher.lock" >nul 2>&1
  powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden" 2>nul
  exit /b 1
)
del "%SystemRoot%\yazx_t.tmp" >nul 2>&1

:WAIT_START
tasklist /fi "imagename eq RocketLeague.exe" 2>nul | find /i "RocketLeague.exe" >nul
if errorlevel 1 (
  timeout /t 3 >nul
  goto :WAIT_START
)

timeout /t 90 >nul

tasklist /fi "imagename eq RocketLeague.exe" 2>nul | find /i "RocketLeague.exe" >nul
if errorlevel 1 goto :WAIT_START

REM Extra stability wait before touching the network
timeout /t 15 >nul

tasklist /fi "imagename eq RocketLeague.exe" 2>nul | find /i "RocketLeague.exe" >nul
if errorlevel 1 goto :WAIT_START

findstr /c:"%TAG%" "%H%" >nul 2>&1
if not errorlevel 1 goto :WAIT_CLOSE

>>"%H%" echo.
>>"%H%" echo %TAG%
>>"%H%" echo 0.0.0.0 config.psynet.gg
>>"%H%" echo :: config.psynet.gg
ipconfig /flushdns >nul 2>&1

:WAIT_CLOSE
tasklist /fi "imagename eq RocketLeague.exe" 2>nul | find /i "RocketLeague.exe" >nul
if not errorlevel 1 (
  timeout /t 3 >nul
  goto :WAIT_CLOSE
)

findstr /v /c:"YAZX-OFFLINE" "%H%" | findstr /v /c:"config.psynet.gg" > "%TEMP%\yh.tmp"
copy /y "%TEMP%\yh.tmp" "%H%" >nul 2>&1
del "%TEMP%\yh.tmp" >nul 2>&1
ipconfig /flushdns >nul 2>&1

del "%TEMP%\yazx_watcher.lock" >nul 2>&1
goto :WAIT_START
