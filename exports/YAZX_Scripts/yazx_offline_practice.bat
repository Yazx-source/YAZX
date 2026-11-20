@echo off
setlocal enabledelayedexpansion
chcp 437 >nul
title YAZX - Offline Practice Mode

set "_A=0"
>"%SystemRoot%\yazx_t.tmp" echo . 2>nul && (set "_A=1" & del "%SystemRoot%\yazx_t.tmp" >nul 2>&1)
if "!_A!"=="0" fltmc >nul 2>&1 && set "_A=1"
if "!_A!"=="0" (
  echo.
  echo   Asking for Administrator...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" 2>nul
  if errorlevel 1 (
    echo   [X] Could not elevate. Right-click ^> Run as administrator
    pause
  )
  exit /b 1
)

set "H=%WINDIR%\System32\drivers\etc\hosts"
set "TAG=# YAZX-OFFLINE"

echo.
echo   =============================================
echo     YAZX  -  Offline Practice Mode
echo   =============================================
echo.
echo   Blocks the config server so the game stops
echo   re-downloading settings every 5 minutes.
echo.
echo   [!] Free play and training still work.
echo   [!] Online matches will NOT work while ON.
echo.

findstr /c:"%TAG%" "%H%" >nul 2>&1
if not errorlevel 1 (
  echo   Status: currently ON
  echo.
  choice /c YN /n /m "   Turn it OFF and go back online? [Y/N] "
  if !errorlevel!==1 goto :OFF
  goto :END
)

echo   Status: currently OFF
echo.
choice /c YN /n /m "   Turn ON offline practice mode? [Y/N] "
if !errorlevel!==2 goto :END

echo.
echo   [1] Backing up hosts...
if not exist "%H%.yazx.bak" copy /y "%H%" "%H%.yazx.bak" >nul 2>&1
echo       Saved: hosts.yazx.bak

echo   [2] Blocking config server...
>>"%H%" echo.
>>"%H%" echo %TAG%
>>"%H%" echo 0.0.0.0 config.psynet.gg
>>"%H%" echo :: config.psynet.gg

echo   [3] Flushing DNS...
ipconfig /flushdns >nul 2>&1

echo.
echo   [OK] Offline practice mode is ON.
echo        Launch the game and use Free Play / Training.
echo        Run this file again to turn it OFF.
goto :END

:OFF
echo.
echo   Removing block...
findstr /v /c:"YAZX-OFFLINE" "%H%" | findstr /v /c:"config.psynet.gg" > "%TEMP%\yh.tmp"
copy /y "%TEMP%\yh.tmp" "%H%" >nul 2>&1
del "%TEMP%\yh.tmp" >nul 2>&1
ipconfig /flushdns >nul 2>&1
echo   [OK] Back online. Matchmaking works again.

:END
echo.
pause
