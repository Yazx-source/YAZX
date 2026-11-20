@echo off

bcdedit /set useplatformtick no
bcdedit /set disabledynamictick yes
bcdedit /set tscsyncpolicy Enhanced

echo DONE.
pause
