@echo off
icacls "C:\Program Files (x86)\Steam\bin\cef\cef.win64\steamwebhelper.exe" /remove:d Everyone
taskkill /F /IM steamwebhelper.exe >nul 2>&1
echo.
echo Done - Steam Web Helper unblocked. Steam.exe itself was NOT touched.
timeout /t 3
