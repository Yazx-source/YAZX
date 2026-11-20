@echo off
title Gaming Mode - made by TTCH
color 0A

:: Check for admin rights (does not depend on LanmanServer service)
cacls.exe "%SystemRoot%\system32\config\system" >nul 2>&1
if '%errorlevel%' NEQ '0' (
    echo This script requires Administrator privileges.
    echo Right-click and "Run as administrator".
    pause
    exit /b 1
)

:menu
cls
echo =====================================
echo     Gaming Mode - made by TTCH      
echo =====================================
echo.
echo  [1] Enable Gaming Mode
echo  [2] Disable Gaming Mode
echo  [3] Exit
echo.
choice /c 123 /n /m "Select option: "

if errorlevel 3 exit /b
if errorlevel 2 goto disable
if errorlevel 1 goto enable

:enable
cls
echo Enabling Gaming Mode...
start cmd.exe /c "netsh int tcp set global autotuninglevel=disabled"
timeout /t 3 /nobreak >nul
echo Gaming Mode ENABLED!
pause
goto menu

:disable
cls
echo Disabling Gaming Mode...
start cmd.exe /c "netsh int tcp set global autotuninglevel=normal"
timeout /t 3 /nobreak >nul
echo Gaming Mode DISABLED!
pause
goto menu
