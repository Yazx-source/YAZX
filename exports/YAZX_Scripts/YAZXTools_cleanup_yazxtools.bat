@echo off
cd /d C:\YAZXTools

del /q watcher.ps1 2>nul
del /q watcher_fast.ps1 2>nul
del /q start_watcher.bat 2>nul
del /q stop_watcher.bat 2>nul
del /q play_steam_killer.bat 2>nul
del /q play_steam_killer_silent.vbs 2>nul
del /q install_steam_killer.bat 2>nul
del /q install_steam_killer.ps1 2>nul
del /q uninstall_steam_killer.bat 2>nul
del /q uninstall_steam_killer.ps1 2>nul
del /q steam_killer_2min.ps1 2>nul
del /q start_steam_killer_2min.bat 2>nul
del /q find_quaked.ps1 2>nul
del /q block_after_game_debug.bat 2>nul
del /q block_debug2.bat 2>nul
del /q check_webhelper_status.bat 2>nul
del /q diagnose_steam_not_opening.bat 2>nul
del /q unblock_debug.bat 2>nul
del /q block_after_game_simple.bat 2>nul
del /q unblock_revert_simple.bat 2>nul

echo.
echo Done. Remaining files in C:\YAZXTools:
dir /b
echo.
pause
