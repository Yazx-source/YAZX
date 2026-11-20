@echo off
setlocal enabledelayedexpansion
chcp 437 >nul
title YAZX - Cache Lock Toggle

set "C=%USERPROFILE%\Documents\My Games\Rocket League\TAGame\Cache"
if not exist "%C%" ( echo   [X] Cache folder not found. Launch the game once. & pause & exit /b 1 )

echo.
echo   ==========================================
echo     YAZX  -  Cache Lock Toggle
echo   ==========================================
echo.
echo   Searching for the config file...
set "F="
for %%A in ("%C%\*") do (
  set "SZ=%%~zA"
  if !SZ! GTR 300000 if !SZ! LSS 1200000 (
    if not defined F findstr /m /c:"ClassPropertyConfig" "%%~fA" >nul 2>&1 && set "F=%%~fA"
  )
)
if not defined F for %%A in ("%C%\WebCache\*") do (
  set "SZ=%%~zA"
  if !SZ! GTR 300000 if !SZ! LSS 1200000 (
    if not defined F findstr /m /c:"ClassPropertyConfig" "%%~fA" >nul 2>&1 && set "F=%%~fA"
  )
)
if not defined F ( echo   [X] Config file not found. & pause & exit /b 1 )
echo   Found.

REM ---- detect real state, not a flag file ----
set "LOCKED=0"
icacls "!F!" 2>nul | findstr /c:"(DENY)" >nul && set "LOCKED=1"
for %%A in ("!F!") do if not "%%~aA"=="%%~aA" set "X=1"
attrib "!F!" | findstr /b /c:"  R" >nul && set "LOCKED=1"

if "!LOCKED!"=="1" (
  echo   Status: LOCKED
  echo.
  choice /c YN /n /m "   Unlock it? [Y/N] "
  if !errorlevel!==2 goto :END
  icacls "!F!" /remove:d "%USERNAME%" >nul 2>&1
  icacls "!F!" /remove:d "Everyone" >nul 2>&1
  attrib -R "!F!" >nul 2>&1
  if exist "%C%\.yazx_lock" del /f /q "%C%\.yazx_lock" >nul 2>&1
  echo.
  echo   [OK] Unlocked. The game can update it again.
  goto :END
)

echo   Status: UNLOCKED
echo.
choice /c YN /n /m "   Lock it? [Y/N] "
if !errorlevel!==2 goto :END

REM ---- backup before locking, never overwrite a good one ----
if not exist "!F!.yazx.bak" (
  copy /y "!F!" "!F!.yazx.bak" >nul 2>&1
  if exist "!F!.yazx.bak" (echo   [1] Backup saved) else (echo   [1] Backup FAILED - continuing)
) else ( echo   [1] Backup already exists - kept )

attrib +R "!F!" >nul 2>&1
if errorlevel 1 (echo   [2] Read-only : FAILED) else (echo   [2] Read-only : ON)
icacls "!F!" /inheritance:d >nul 2>&1
icacls "!F!" /deny "%USERNAME%:(WD,AD,WEA,WA,DE)" >nul 2>&1
if errorlevel 1 (echo   [3] Write lock: not applied) else (echo   [3] Write lock: ON)
echo.
echo   [OK] Locked. Run this file again to unlock.

:END
echo.
pause
