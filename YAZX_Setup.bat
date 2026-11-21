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
:: Auto-detect backup folder: check script drive first, then other drives
set "SCRIPT_DRIVE=%~d0"
set "BACKUP_DIR="
if exist "%SCRIPT_DRIVE%\YAZX_Backup" (
    set "BACKUP_DIR=%SCRIPT_DRIVE%\YAZX_Backup"
) else (
    for %%D in (E D C F G) do (
        if not defined BACKUP_DIR if exist "%%D:\YAZX_Backup" set "BACKUP_DIR=%%D:\YAZX_Backup"
    )
)
if not defined BACKUP_DIR set "BACKUP_DIR=%SCRIPT_DRIVE%\YAZX_Backup"
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

:: Tool status check (informational only)
echo  Tool Status:
set "TOOLS_OK=0"
set "TOOLS_MISS=0"
for %%d in (Sysinternals MouseTester WinMTR CapFrameX OO_ShutUp10 USBTreeView ISLC LatencyMon QuickCPU GPU-Z ThrottleStop DDU IRQControl) do (
    if exist "%YAZX_DIR%\tools\%%d" (
        set /a TOOLS_OK+=1
    ) else (
        set /a TOOLS_MISS+=1
    )
)
for %%d in (CrystalDiskInfo CrystalDiskMark HWiNFO SG_TCP_Optimizer) do (
    set "HAS_FILE="
    for %%f in ("%YAZX_DIR%\tools\%%d\*.*") do set "HAS_FILE=1"
    if not defined HAS_FILE set /a TOOLS_MISS+=1
)
set /a TOOLS_TOTAL=%TOOLS_OK%+%TOOLS_MISS%
if %TOOLS_MISS% GTR 0 (
    echo  [!] %TOOLS_OK% of %TOOLS_TOTAL% tools ready, %TOOLS_MISS% not found
) else (
    echo  [+] All %TOOLS_TOTAL% tools present
)
echo.

:menu
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
echo   [C]  MSI Mode             - Interrupt mode (7 devices)
echo   [D]  Power Plan           - YAZX Ultimate Performance
echo   [E]  Privacy              - Hosts/Telemetry cleanup
echo   [F]  Oneclick             - Run Oneclick tweaker (LAST!)
echo   [G]  New Tweaks           - VBS/HVCI/Audio + candidate review
echo   [H]  Autologgers          - Disable ETW autologger sessions
echo.
echo   [T]  Download Tools       - Auto-download all optimization tools
echo   [A]  Run ALL (Smart Defaults, one-click)
echo   [V]  Phase 2.5 Exports    - Kernel/Power/VST/Profiles (manual review)
echo   [R]  Registry FULL Restore (from backup exports)
echo   [Q]  Quit
echo.

choice /c 123456789ACDEFGHTVRQ /n /m "  Select: "

if errorlevel 20 exit /b
if errorlevel 19 goto run_reg_full_restore
if errorlevel 18 goto run_phase25
if errorlevel 17 goto run_downloadtools
if errorlevel 16 goto run_autologgers
if errorlevel 15 goto run_newtweaks
if errorlevel 14 goto run_oneclick
if errorlevel 13 goto run_privacy
if errorlevel 12 goto run_power
if errorlevel 11 goto run_msi
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
echo  ═══════════════════════════════════════════
echo   YAZX Smart Setup — Running ALL with defaults
echo  ═══════════════════════════════════════════
echo.
echo  Creating system restore point...
powershell -Command "try { Checkpoint-Computer -Description 'YAZX Pre-Setup' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Host '  [OK] Restore point created' } catch { Write-Host '  [!] Restore point skipped (not available)' }"
echo  [%DATE% %TIME%] Running ALL modules (Auto mode) >> "%LOG_FILE%"
echo.
echo  Downloading tools (if missing)...
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\16_DownloadTools.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
echo.
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\01_SystemCheck.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\02_NVIDIADriver.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\03_Programs.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\04_Configs.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
echo.
echo  Applying registry tweaks...
regedit /s "%YAZX_DIR%\registry\YAZX_System.reg"
echo  [%DATE% %TIME%] Registry System: Applied (UAC, WER, Maintenance) >> "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_Cosmetic.reg"
echo  [%DATE% %TIME%] Registry Cosmetic: Applied >> "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_Gaming.reg"
echo  [%DATE% %TIME%] Registry Gaming: Applied >> "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_Network.reg"
echo  [%DATE% %TIME%] Registry Network: Applied >> "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_NVIDIA.reg"
echo  [%DATE% %TIME%] Registry NVIDIA: Applied >> "%LOG_FILE%"
regedit /s "%YAZX_DIR%\registry\YAZX_Hardware.reg"
echo  [%DATE% %TIME%] Registry Hardware: Applied (AHCI, NVMe, USB) >> "%LOG_FILE%"
echo  [OK] All registry tweaks applied.
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\08_Services.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\09_BCDTweaks.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\10_MSIMode.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\11_PowerPlan.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\12_Privacy.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
echo.
regedit /s "%YAZX_DIR%\registry\YAZX_NewTweaks.reg"
echo  [%DATE% %TIME%] Registry NewTweaks: Applied >> "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\14_NewTweaks.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\15_Autologgers.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%" -Auto
echo.
echo  ═══════════════════════════════════════════
echo   ALL 16 modules applied with YAZX defaults
echo  ═══════════════════════════════════════════
echo.
echo  [!] Module 13 (Oneclick) must be run manually - download from:
echo      https://github.com/QuakedK/Oneclick/releases
echo.
echo  Log file: %LOG_FILE%
echo  [%DATE% %TIME%] ALL modules completed (16 modules, Auto mode). >> "%LOG_FILE%"
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
regedit /s "%YAZX_DIR%\registry\YAZX_NVIDIA.reg"
regedit /s "%YAZX_DIR%\registry\YAZX_Hardware.reg"
echo  [%DATE% %TIME%] Registry Gaming + NVIDIA + Hardware: Applied >> "%LOG_FILE%"
goto done

:run_reg_network
regedit /s "%YAZX_DIR%\registry\YAZX_Network.reg"
echo  [%DATE% %TIME%] Registry Network: Applied >> "%LOG_FILE%"
goto done

:run_msi
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\10_MSIMode.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_reg_full_restore
echo.
echo  ══════════════════════════════════════════
echo   Registry FULL Restore from Backup
echo  ══════════════════════════════════════════
echo.
echo  This imports ALL registry exports from the backup folder.
echo  Source: %BACKUP_DIR%\yazx_AllTweakRegistry
echo.
echo  [1] AllTweakRegistry (41 files - comprehensive system state)
echo  [2] TweakRegistry    (36 files - targeted tweak parameters)
echo  [3] Both
echo  [Q] Cancel
echo.
choice /c 123Q /n /m "  Select restore source: "
if errorlevel 4 goto done
if errorlevel 3 goto restore_both
if errorlevel 2 goto restore_tweak
if errorlevel 1 goto restore_all

:restore_all
echo  Importing AllTweakRegistry...
for %%f in ("%BACKUP_DIR%\yazx_AllTweakRegistry\*.reg") do (
    findstr /b /c:"Windows Registry Editor" "%%f" >nul 2>&1
    if errorlevel 1 (
        echo  [!!] SKIPPED invalid reg file: %%~nxf
        echo  [%DATE% %TIME%] SECURITY: Skipped non-registry file: %%~nxf >> "%LOG_FILE%"
    ) else (
        regedit /s "%%f"
        echo  [OK] Imported: %%~nxf
        echo  [%DATE% %TIME%] AllTweakRegistry: Imported %%~nxf >> "%LOG_FILE%"
    )
)
echo  [%DATE% %TIME%] AllTweakRegistry: Restore completed >> "%LOG_FILE%"
goto done

:restore_tweak
echo  Importing TweakRegistry...
for %%f in ("%BACKUP_DIR%\yazx_TweakRegistry\*.reg") do (
    findstr /b /c:"Windows Registry Editor" "%%f" >nul 2>&1
    if errorlevel 1 (
        echo  [!!] SKIPPED invalid reg file: %%~nxf
        echo  [%DATE% %TIME%] SECURITY: Skipped non-registry file: %%~nxf >> "%LOG_FILE%"
    ) else (
        regedit /s "%%f"
        echo  [OK] Imported: %%~nxf
        echo  [%DATE% %TIME%] TweakRegistry: Imported %%~nxf >> "%LOG_FILE%"
    )
)
echo  [%DATE% %TIME%] TweakRegistry: Restore completed >> "%LOG_FILE%"
goto done

:restore_both
echo  Importing AllTweakRegistry...
for %%f in ("%BACKUP_DIR%\yazx_AllTweakRegistry\*.reg") do (
    findstr /b /c:"Windows Registry Editor" "%%f" >nul 2>&1
    if errorlevel 1 (
        echo  [!!] SKIPPED invalid reg file: %%~nxf
    ) else (
        regedit /s "%%f"
        echo  [OK] Imported: %%~nxf
    )
)
echo  Importing TweakRegistry...
for %%f in ("%BACKUP_DIR%\yazx_TweakRegistry\*.reg") do (
    findstr /b /c:"Windows Registry Editor" "%%f" >nul 2>&1
    if errorlevel 1 (
        echo  [!!] SKIPPED invalid reg file: %%~nxf
    ) else (
        regedit /s "%%f"
        echo  [OK] Imported: %%~nxf
    )
)
echo  [%DATE% %TIME%] Both AllTweakRegistry + TweakRegistry: Full restore completed >> "%LOG_FILE%"
echo  [OK] Full registry restore complete.
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

:run_newtweaks
echo.
echo  Applying New Tweaks (VBS/HVCI/Audio + SAFE registry)...
regedit /s "%YAZX_DIR%\registry\YAZX_NewTweaks.reg"
echo  [%DATE% %TIME%] Registry NewTweaks: Applied >> "%LOG_FILE%"
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\14_NewTweaks.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
echo.
echo  Candidate tweaks (Timer Resolution, Memory Compression, P-core, ASPM)
echo  are NOT auto-applied. Each must be tested individually.
goto done

:run_autologgers
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\15_Autologgers.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_downloadtools
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\modules\16_DownloadTools.ps1" -YazxDir "%YAZX_DIR%" -BackupDir "%BACKUP_DIR%" -LogFile "%LOG_FILE%"
goto done

:run_oneclick
echo.
echo  Oneclick must be downloaded and run separately:
echo  https://github.com/QuakedK/Oneclick/releases
echo  Run it AFTER all other YAZX modules.
echo.
echo  [%DATE% %TIME%] Oneclick: User directed to download >> "%LOG_FILE%"
goto done

:run_phase25
echo.
echo  ══════════════════════════════════════════
echo   Phase 2.5 Discovered Exports
echo  ══════════════════════════════════════════
echo.
echo  These are settings discovered during Phase 2.5 audit.
echo  NOT included in Run ALL — each requires manual review.
echo  Candidate and Experimental tweaks are NOT applied here.
echo.
echo  [1] Import Kernel tweaks (11 discovered settings from Kernel.reg)
echo  [2] Import Power settings (Power_Control.reg — TTCH plan)
echo  [3] Import power plans (EonX.pow, EonX_Idle.pow via powercfg)
echo  [4] Import ExplorerPatcher + OpenShell registry exports
echo  [5] Restore EQ APO VST plugins + mic.txt config
echo  [6] Rebuild TTCH Power Plan (from saved values)
echo  [7] Restore hosts file (with backup of current)
echo  [8] Restore user settings (HKCU_Run, DirectX GPU, BackgroundApps)
echo  [9] All 1-5, 7-8 (skip TTCH rebuild)
echo  [Q] Back to main menu
echo.
choice /c 123456789Q /n /m "  Select: "
if errorlevel 10 goto done
if errorlevel 9 goto phase25_all
if errorlevel 8 goto phase25_usersettings
if errorlevel 7 goto phase25_hosts
if errorlevel 6 goto phase25_ttch_rebuild
if errorlevel 5 goto phase25_eqapo
if errorlevel 4 goto phase25_explorer
if errorlevel 3 goto phase25_powplans
if errorlevel 2 goto phase25_powerreg
if errorlevel 1 goto phase25_kernel

:phase25_kernel
echo.
echo  Importing Kernel tweaks...
if exist "%YAZX_DIR%\exports\TweakRegistry\Kernel.reg" (
    regedit /s "%YAZX_DIR%\exports\TweakRegistry\Kernel.reg"
    echo  [OK] Kernel.reg imported (11 settings: timer, DPC, hetero CPU policy)
    echo  [%DATE% %TIME%] Phase2.5 Kernel.reg: Imported >> "%LOG_FILE%"
) else (
    echo  [!] exports\TweakRegistry\Kernel.reg not found — skipping
    echo  [%DATE% %TIME%] Phase2.5 Kernel.reg: NOT FOUND >> "%LOG_FILE%"
)
if exist "%YAZX_DIR%\exports\TweakRegistry\FileSystem.reg" (
    regedit /s "%YAZX_DIR%\exports\TweakRegistry\FileSystem.reg"
    echo  [OK] FileSystem.reg imported (NTFS optimizations)
    echo  [%DATE% %TIME%] Phase2.5 FileSystem.reg: Imported >> "%LOG_FILE%"
)
goto done

:phase25_powerreg
echo.
echo  Importing Power settings from Power_Control.reg...
if exist "%YAZX_DIR%\exports\Power_Control.reg" (
    regedit /s "%YAZX_DIR%\exports\Power_Control.reg"
    echo  [OK] Power_Control.reg imported (1637 KB — full TTCH plan registry)
    echo  [%DATE% %TIME%] Phase2.5 Power_Control.reg: Imported >> "%LOG_FILE%"
) else (
    echo  [!] exports\Power_Control.reg not found — skipping
    echo  [%DATE% %TIME%] Phase2.5 Power_Control.reg: NOT FOUND >> "%LOG_FILE%"
)
if exist "%YAZX_DIR%\exports\CPU_PowerSettings.reg" (
    regedit /s "%YAZX_DIR%\exports\CPU_PowerSettings.reg"
    echo  [OK] CPU_PowerSettings.reg imported (836 KB — 570 power schema values)
    echo  [%DATE% %TIME%] Phase2.5 CPU_PowerSettings.reg: Imported >> "%LOG_FILE%"
)
goto done

:phase25_powplans
echo.
echo  Importing power plans via powercfg...
if exist "%YAZX_DIR%\exports\PowerPlans\EonX.pow" (
    powercfg /import "%YAZX_DIR%\exports\PowerPlans\EonX.pow"
    echo  [OK] EonX.pow imported
    echo  [%DATE% %TIME%] Phase2.5 EonX.pow: Imported >> "%LOG_FILE%"
) else (
    echo  [!] EonX.pow not found
)
if exist "%YAZX_DIR%\exports\PowerPlans\EonX_Idle.pow" (
    powercfg /import "%YAZX_DIR%\exports\PowerPlans\EonX_Idle.pow"
    echo  [OK] EonX_Idle.pow imported
    echo  [%DATE% %TIME%] Phase2.5 EonX_Idle.pow: Imported >> "%LOG_FILE%"
) else (
    echo  [!] EonX_Idle.pow not found
)
echo  [!] TTCH_UltimatePerformance.pow is 0 bytes — NOT imported.
echo      Use option [6] to rebuild TTCH plan from saved values.
goto done

:phase25_explorer
echo.
echo  Importing ExplorerPatcher + OpenShell settings...
if exist "%YAZX_DIR%\exports\ExplorerPatcher\ExplorerPatcher_HKCU.reg" (
    regedit /s "%YAZX_DIR%\exports\ExplorerPatcher\ExplorerPatcher_HKCU.reg"
    echo  [OK] ExplorerPatcher settings imported
    echo  [%DATE% %TIME%] Phase2.5 ExplorerPatcher: Imported >> "%LOG_FILE%"
) else (
    echo  [!] ExplorerPatcher_HKCU.reg not found
)
if exist "%YAZX_DIR%\exports\OpenShell\OpenShell_HKCU.reg" (
    regedit /s "%YAZX_DIR%\exports\OpenShell\OpenShell_HKCU.reg"
    echo  [OK] OpenShell settings imported
    echo  [%DATE% %TIME%] Phase2.5 OpenShell: Imported >> "%LOG_FILE%"
) else (
    echo  [!] OpenShell_HKCU.reg not found
)
goto done

:phase25_eqapo
echo.
echo  Restoring EQ APO VST plugins + mic config...
echo  [!] This requires Equalizer APO to be installed first.
echo.
set "EQAPO_DIR=C:\Program Files\EqualizerAPO"
if exist "%EQAPO_DIR%" (
    echo  [+] Equalizer APO found at %EQAPO_DIR%
    if exist "%YAZX_DIR%\exports\VSTPlugins\rnnoise_stereo.dll" (
        copy /y "%YAZX_DIR%\exports\VSTPlugins\rnnoise_stereo.dll" "%EQAPO_DIR%\VSTPlugins\" >nul 2>&1
        echo  [OK] rnnoise_stereo.dll copied
    )
    if exist "%YAZX_DIR%\exports\VSTPlugins\ReaPlugs" (
        xcopy /s /e /y /q "%YAZX_DIR%\exports\VSTPlugins\ReaPlugs\*" "%EQAPO_DIR%\VSTPlugins\ReaPlugs\" >nul 2>&1
        echo  [OK] ReaPlugs suite copied
    )
    if exist "%YAZX_DIR%\exports\EqualizerAPO\mic.txt" (
        copy /y "%YAZX_DIR%\exports\EqualizerAPO\mic.txt" "%EQAPO_DIR%\config\mic.txt" >nul 2>&1
        echo  [OK] mic.txt copied (HyperX mic VST chain)
    )
    echo  [!] Add "Include: mic.txt" to %EQAPO_DIR%\config\config.txt manually
    echo  [%DATE% %TIME%] Phase2.5 EQ APO: VST + mic.txt restored >> "%LOG_FILE%"
) else (
    echo  [!] Equalizer APO not installed at %EQAPO_DIR%
    echo      Install EQ APO first, then run this option again.
    echo  [%DATE% %TIME%] Phase2.5 EQ APO: NOT INSTALLED >> "%LOG_FILE%"
)
goto done

:phase25_ttch_rebuild
echo.
echo  Rebuilding TTCH ULTIMATE PERFORMANCE plan from saved values...
powershell -ExecutionPolicy Bypass -File "%YAZX_DIR%\exports\PowerPlans\YAZX_TTCH_Rebuild.ps1" -YazxDir "%YAZX_DIR%" -LogFile "%LOG_FILE%"
goto done

:phase25_hosts
echo.
echo  Restoring hosts file...
if exist "%YAZX_DIR%\exports\hosts" (
    echo  Backing up current hosts file...
    copy "C:\Windows\System32\drivers\etc\hosts" "C:\Windows\System32\drivers\etc\hosts.yazx_bak" /Y >nul 2>&1
    copy "%YAZX_DIR%\exports\hosts" "C:\Windows\System32\drivers\etc\hosts" /Y >nul 2>&1
    echo  [OK] hosts file restored (backup saved as hosts.yazx_bak)
    echo  [%DATE% %TIME%] Phase2.5 hosts: Restored (backup created) >> "%LOG_FILE%"
) else (
    echo  [!] exports\hosts not found — skipping
    echo  [%DATE% %TIME%] Phase2.5 hosts: NOT FOUND >> "%LOG_FILE%"
)
goto done

:phase25_usersettings
echo.
echo  Restoring user settings (HKCU — per-user, separate from system tweaks)...
echo.
if exist "%YAZX_DIR%\exports\HKCU_Run.reg" (
    regedit /s "%YAZX_DIR%\exports\HKCU_Run.reg"
    echo  [OK] HKCU_Run.reg imported (startup programs)
    echo  [%DATE% %TIME%] Phase2.5 HKCU_Run.reg: Imported >> "%LOG_FILE%"
) else (
    echo  [!] HKCU_Run.reg not found
)
if exist "%YAZX_DIR%\exports\DirectX_UserGpuPreferences.reg" (
    regedit /s "%YAZX_DIR%\exports\DirectX_UserGpuPreferences.reg"
    echo  [OK] DirectX_UserGpuPreferences.reg imported (per-app GPU assignment)
    echo  [%DATE% %TIME%] Phase2.5 DirectX_UserGpuPreferences.reg: Imported >> "%LOG_FILE%"
) else (
    echo  [!] DirectX_UserGpuPreferences.reg not found
)
if exist "%YAZX_DIR%\exports\BackgroundApps.reg" (
    regedit /s "%YAZX_DIR%\exports\BackgroundApps.reg"
    echo  [OK] BackgroundApps.reg imported (per-app background permissions)
    echo  [%DATE% %TIME%] Phase2.5 BackgroundApps.reg: Imported >> "%LOG_FILE%"
)
if exist "%YAZX_DIR%\exports\PowerThrottling.reg" (
    regedit /s "%YAZX_DIR%\exports\PowerThrottling.reg"
    echo  [OK] PowerThrottling.reg imported
    echo  [%DATE% %TIME%] Phase2.5 PowerThrottling.reg: Imported >> "%LOG_FILE%"
)
if exist "%YAZX_DIR%\exports\Bitsum_Registry.reg" (
    regedit /s "%YAZX_DIR%\exports\Bitsum_Registry.reg"
    echo  [OK] Bitsum_Registry.reg imported (Process Lasso registry settings)
    echo  [%DATE% %TIME%] Phase2.5 Bitsum_Registry.reg: Imported >> "%LOG_FILE%"
)
echo.
echo  [OK] User settings restore complete.
goto done

:phase25_all
echo.
echo  Running Phase 2.5 exports 1-5, 7-8 in order...
echo  [%DATE% %TIME%] Phase2.5: Running ALL discovered exports >> "%LOG_FILE%"
echo.
:: 1. Kernel
if exist "%YAZX_DIR%\exports\TweakRegistry\Kernel.reg" (
    regedit /s "%YAZX_DIR%\exports\TweakRegistry\Kernel.reg"
    echo  [OK] Kernel.reg imported
)
if exist "%YAZX_DIR%\exports\TweakRegistry\FileSystem.reg" (
    regedit /s "%YAZX_DIR%\exports\TweakRegistry\FileSystem.reg"
    echo  [OK] FileSystem.reg imported
)
:: 2. Power registry
if exist "%YAZX_DIR%\exports\Power_Control.reg" (
    regedit /s "%YAZX_DIR%\exports\Power_Control.reg"
    echo  [OK] Power_Control.reg imported
)
if exist "%YAZX_DIR%\exports\CPU_PowerSettings.reg" (
    regedit /s "%YAZX_DIR%\exports\CPU_PowerSettings.reg"
    echo  [OK] CPU_PowerSettings.reg imported
)
:: 3. Power plans
if exist "%YAZX_DIR%\exports\PowerPlans\EonX.pow" (
    powercfg /import "%YAZX_DIR%\exports\PowerPlans\EonX.pow"
    echo  [OK] EonX.pow imported
)
if exist "%YAZX_DIR%\exports\PowerPlans\EonX_Idle.pow" (
    powercfg /import "%YAZX_DIR%\exports\PowerPlans\EonX_Idle.pow"
    echo  [OK] EonX_Idle.pow imported
)
:: 4. ExplorerPatcher + OpenShell
if exist "%YAZX_DIR%\exports\ExplorerPatcher\ExplorerPatcher_HKCU.reg" (
    regedit /s "%YAZX_DIR%\exports\ExplorerPatcher\ExplorerPatcher_HKCU.reg"
    echo  [OK] ExplorerPatcher imported
)
if exist "%YAZX_DIR%\exports\OpenShell\OpenShell_HKCU.reg" (
    regedit /s "%YAZX_DIR%\exports\OpenShell\OpenShell_HKCU.reg"
    echo  [OK] OpenShell imported
)
:: 5. EQ APO
set "EQAPO_DIR=C:\Program Files\EqualizerAPO"
if exist "%EQAPO_DIR%" (
    if exist "%YAZX_DIR%\exports\VSTPlugins\rnnoise_stereo.dll" (
        copy /y "%YAZX_DIR%\exports\VSTPlugins\rnnoise_stereo.dll" "%EQAPO_DIR%\VSTPlugins\" >nul 2>&1
    )
    if exist "%YAZX_DIR%\exports\VSTPlugins\ReaPlugs" (
        xcopy /s /e /y /q "%YAZX_DIR%\exports\VSTPlugins\ReaPlugs\*" "%EQAPO_DIR%\VSTPlugins\ReaPlugs\" >nul 2>&1
    )
    if exist "%YAZX_DIR%\exports\EqualizerAPO\mic.txt" (
        copy /y "%YAZX_DIR%\exports\EqualizerAPO\mic.txt" "%EQAPO_DIR%\config\mic.txt" >nul 2>&1
    )
    echo  [OK] EQ APO VST + mic.txt restored
) else (
    echo  [!] EQ APO not installed — VST restore skipped
)
:: 7. Hosts file
if exist "%YAZX_DIR%\exports\hosts" (
    copy "C:\Windows\System32\drivers\etc\hosts" "C:\Windows\System32\drivers\etc\hosts.yazx_bak" /Y >nul 2>&1
    copy "%YAZX_DIR%\exports\hosts" "C:\Windows\System32\drivers\etc\hosts" /Y >nul 2>&1
    echo  [OK] hosts file restored (backup: hosts.yazx_bak)
)
:: 8. User settings (HKCU)
if exist "%YAZX_DIR%\exports\HKCU_Run.reg" (
    regedit /s "%YAZX_DIR%\exports\HKCU_Run.reg"
    echo  [OK] HKCU_Run.reg imported
)
if exist "%YAZX_DIR%\exports\DirectX_UserGpuPreferences.reg" (
    regedit /s "%YAZX_DIR%\exports\DirectX_UserGpuPreferences.reg"
    echo  [OK] DirectX_UserGpuPreferences.reg imported
)
if exist "%YAZX_DIR%\exports\BackgroundApps.reg" (
    regedit /s "%YAZX_DIR%\exports\BackgroundApps.reg"
    echo  [OK] BackgroundApps.reg imported
)
if exist "%YAZX_DIR%\exports\PowerThrottling.reg" (
    regedit /s "%YAZX_DIR%\exports\PowerThrottling.reg"
    echo  [OK] PowerThrottling.reg imported
)
if exist "%YAZX_DIR%\exports\Bitsum_Registry.reg" (
    regedit /s "%YAZX_DIR%\exports\Bitsum_Registry.reg"
    echo  [OK] Bitsum_Registry.reg imported
)
echo.
echo  [!] TTCH rebuild not included — use option [6] separately
echo  [%DATE% %TIME%] Phase2.5: ALL discovered exports (1-5, 7-8) completed >> "%LOG_FILE%"
goto done

:done
echo.
echo  ═══════════════════════════════════
echo       Module Complete
echo  ═══════════════════════════════════
echo.
choice /c MQ /n /m "  [M] Return to Menu  [Q] Quit: "
if errorlevel 2 goto quit
goto menu

:quit
echo.
echo  [%DATE% %TIME%] YAZX Setup Ended. >> "%LOG_FILE%"
echo  YAZX Setup finished. Goodbye!
echo.
pause
