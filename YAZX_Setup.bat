@echo off
:: ================================================================
::  YAZX Setup - Complete System Restoration Tool
::  Made by YAZX
::  Restores all tweaks, programs, and configs after fresh install
:: ================================================================
title YAZX Setup
color 0A
chcp 65001 >nul 2>&1

:: Admin check
cacls.exe "%SystemRoot%\system32\config\system" >nul 2>&1
if '%errorlevel%' NEQ '0' (
    echo [ERROR] Run as Administrator!
    echo Right-click and "Run as administrator".
    pause
    exit /b 1
)

:: Set paths
set "YAZX_DIR=%~dp0"
set "YAZX_DIR=%YAZX_DIR:~0,-1%"
set "BACKUP_DIR=E:\YAZX_Backup"
set "LOG_DIR=%YAZX_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\YAZX_Setup_Log.txt"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo.
echo  ██    ██  █████  ███████ ██   ██
echo   ██  ██  ██   ██    ███  ██   ██
echo    ████   ███████   ███    █████
echo     ██    ██   ██  ███    ██   ██
echo     ██    ██   ██ ███████ ██   ██
echo.
echo  ═══════════════════════════════════
echo       YAZX Setup - System Restore
echo  ═══════════════════════════════════
echo.
echo  [%DATE% %TIME%] YAZX Setup Started. >> "%LOG_FILE%"

:: Check for backup folder
if exist "%BACKUP_DIR%" (
    echo  [✔] Backup folder found: %BACKUP_DIR%
    echo  [%DATE% %TIME%] Backup folder: Found at %BACKUP_DIR% >> "%LOG_FILE%"
) else (
    echo  [!] Backup folder not found at %BACKUP_DIR%
    echo      Some features will download instead of local copy.
    echo  [%DATE% %TIME%] Backup folder: NOT FOUND >> "%LOG_FILE%"
)

echo.
echo  Modules (ordered by risk - lowest first):
echo.
echo   [1]  System Check         - Verify compatibility
echo   [2]  NVIDIA Driver        - Install with NVCleanInstall
echo   [3]  Programs             - Install all applications
echo   [4]  Configs              - Restore all configurations
echo   [5]  Registry - Cosmetic  - UI/Shell/Explorer tweaks
echo   [6]  Registry - Gaming    - GPU/MMCSS/Memory/Priority
echo   [7]  Registry - Network   - TCP/Adapter optimization
echo   [8]  Services             - Disable unnecessary services
echo   [9]  BCD Tweaks           - Boot timer configuration
echo   [10] MSI Mode             - Interrupt mode (7 devices)
echo   [11] Power Plan           - TTCH Ultimate Performance
echo   [12] Privacy              - Hosts/Telemetry cleanup
echo   [13] Oneclick             - Run Oneclick tweaker (LAST!)
echo.
echo   [A]  Run ALL (1-13 in order)
echo   [Q]  Quit
echo.

choice /c 123456789ABCDQ /n /m "  Select: "

if errorlevel 14 exit /b
if errorlevel 13 goto run_oneclick
if errorlevel 12 goto run_privacy
if errorlevel 11 goto run_power
if errorlevel 10 goto run_all
set "module_choice=%errorlevel%"

:: Map choices
if "%module_choice%"=="1" goto run_syscheck
if "%module_choice%"=="2" goto run_nvidia
if "%module_choice%"=="3" goto run_programs
if "%module_choice%"=="4" goto run_configs
if "%module_choice%"=="5" goto run_reg_cosmetic
if "%module_choice%"=="6" goto run_reg_gaming
if "%module_choice%"=="7" goto run_reg_network
if "%module_choice%"=="8" goto run_services
if "%module_choice%"=="9" goto run_bcd

:run_all
echo.
echo  Running ALL modules in order...
echo  [%DATE% %TIME%] Running ALL modules >> "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\01_SystemCheck.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\02_NVIDIADriver.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\03_Programs.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\04_Configs.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_Cosmetic.reg"
echo  [%DATE% %TIME%] Registry Cosmetic: Applied >> "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_Gaming.reg"
echo  [%DATE% %TIME%] Registry Gaming: Applied >> "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_Network.reg"
echo  [%DATE% %TIME%] Registry Network: Applied >> "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\08_Services.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\09_BCDTweaks.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\10_MSIMode.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\11_PowerPlan.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\12_Privacy.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
echo.
echo  [!] Module 13 (Oneclick) must be run manually - download from:
echo      https://github.com/QuakedK/Oneclick/releases
echo.
echo  [%DATE% %TIME%] ALL modules completed. Oneclick skipped (run manually). >> "%LOG_FILE%"
goto done

:run_syscheck
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\01_SystemCheck.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_nvidia
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\02_NVIDIADriver.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_programs
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\03_Programs.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_configs
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\04_Configs.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_reg_cosmetic
regedit /s "%YAZX_DIR%\registry\YAZX_Cosmetic.reg"
echo  [%DATE% %TIME%] Registry Cosmetic: Applied >> "%LOG_FILE%"
goto done

:run_reg_gaming
regedit /s "%YAZX_DIR%\registry\YAZX_Gaming.reg"
echo  [%DATE% %TIME%] Registry Gaming: Applied >> "%LOG_FILE%"
goto done

:run_reg_network
regedit /s "%YAZX_DIR%\registry\YAZX_Network.reg"
echo  [%DATE% %TIME%] Registry Network: Applied >> "%LOG_FILE%"
goto done

:run_services
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\08_Services.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_bcd
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\09_BCDTweaks.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_power
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\11_PowerPlan.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_privacy
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\12_Privacy.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_oneclick
echo.
echo  Oneclick must be downloaded and run separately:
echo  https://github.com/QuakedK/Oneclick/releases
echo  Run it AFTER all other YAZX modules.
echo.
echo  [%DATE% %TIME%] Oneclick: User directed to download >> "%LOG_FILE%"
goto done

:done
echo.
echo  ═══════════════════════════════════
echo       YAZX Setup Complete!
echo  ═══════════════════════════════════
echo  [%DATE% %TIME%] YAZX Setup Ended. >> "%LOG_FILE%"
echo.
pause
