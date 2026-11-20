@echo off
title YAZX Memory Tool - Launcher

REM Check admin rights
>"%SystemRoot%\yazx_t2.tmp" echo . 2>nul
if not exist "%SystemRoot%\yazx_t2.tmp" (
  echo   Asking for Administrator...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
del "%SystemRoot%\yazx_t2.tmp" >nul 2>&1

REM Force the TRUE 64-bit PowerShell via the Sysnative alias, bypassing
REM WOW64 file-system redirection entirely (no download needed - built into Windows)
if exist "%WINDIR%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" (
  "%WINDIR%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0yazx_memory_tool.ps1"
) else (
  REM Already on 64-bit shell (Sysnative alias only exists inside WOW64) - normal launch
  powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0yazx_memory_tool.ps1"
)
