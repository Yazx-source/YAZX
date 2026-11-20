@echo off
cacls.exe "%SystemRoot%\system32\config\system" >nul 2>&1
if '%errorlevel%' NEQ '0' (
    echo Run as Administrator!
    pause
    exit /b 1
)

bcdedit /set useplatformtick yes
bcdedit /set disabledynamictick yes
bcdedit /set tscsyncpolicy Enhanced

echo DONE.
pause
