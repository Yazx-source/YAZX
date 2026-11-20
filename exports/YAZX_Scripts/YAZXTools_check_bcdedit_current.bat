@echo off
bcdedit /enum | findstr /i "platformtick dynamictick tscsyncpolicy"
pause
