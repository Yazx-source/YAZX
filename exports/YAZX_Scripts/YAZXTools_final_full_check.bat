@echo off
echo ================= STEAM WEB HELPER =================
echo Permission status:
icacls "C:\Program Files (x86)\Steam\bin\cef\cef.win64\steamwebhelper.exe"
echo.
echo Leftover scheduled tasks (should show none of these):
schtasks /query /tn "KillSteamWebHelper" 2>&1 | findstr /i "ERROR SUCCESS"
schtasks /query /tn "BlockSteamHelperOnLogon" 2>&1 | findstr /i "ERROR SUCCESS"
schtasks /query /tn "UnblockSteamHelperOnShutdown" 2>&1 | findstr /i "ERROR SUCCESS"
echo.

echo ================= DESKTOP CONTEXT MENU =================
reg query "HKEY_CLASSES_ROOT\DesktopBackground\Shell" | findstr /i "GameMode Steam"
echo.

echo ================= LATENCY / PERFORMANCE TWEAKS =================
echo DisablePagingExecutive (expect 1):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive 2>nul
echo.
echo LargeSystemCache (expect: not found = default):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache 2>nul
echo.
echo HwSchMode / HAGS (expect 2):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode 2>nul
echo.
echo SystemResponsiveness:
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness 2>nul
echo.
echo TcpAckFrequency on real adapter (expect: not found = reverted to default):
reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{6ea6b570-a20c-40e4-b532-299ee27ebb28}" /v TcpAckFrequency 2>nul
echo.
echo Win32PrioritySeparation (expect 0x2a):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation 2>nul
echo.

echo ================= POWER PLAN =================
powercfg /getactivescheme
echo.
powercfg /list
echo.

echo ================= UAC (informational only) =================
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2>nul
echo.

pause
