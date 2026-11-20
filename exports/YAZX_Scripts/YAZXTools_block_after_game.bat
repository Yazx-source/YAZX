@echo off
taskkill /F /IM steamwebhelper.exe
icacls "C:\Program Files (x86)\Steam\bin\cef\cef.win64\steamwebhelper.exe" /deny Everyone:(X)
echo.
echo Done - Steam Web Helper blocked. Steam.exe itself was NOT touched.
timeout /t 3
