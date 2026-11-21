param($YazxDir, $BackupDir, $LogFile, [switch]$Auto)
# YAZX Module 09 - BCD Timer Tweaks
# From TTCH TIMERS configuration

. "$PSScriptRoot\YAZX_Common.ps1"
function Log($msg) { YAZX-Log $LogFile $msg }

Write-Host "`n  === YAZX Module 09: BCD Tweaks ===" -ForegroundColor Cyan
Log "Module 09 BCDTweaks: Started"

# TTCH Timer settings
Write-Host "  Applying TTCH timer configuration..." -ForegroundColor Yellow

bcdedit /set useplatformtick yes 2>$null
Write-Host "  [OK] useplatformtick = yes" -ForegroundColor Green

bcdedit /set disabledynamictick yes 2>$null
Write-Host "  [OK] disabledynamictick = yes" -ForegroundColor Green

bcdedit /set tscsyncpolicy Enhanced 2>$null
Write-Host "  [OK] tscsyncpolicy = Enhanced" -ForegroundColor Green

# GlobalTimerResolutionRequests (allow apps to request timer resolution)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d 1 /f 2>$null | Out-Null
Write-Host "  [OK] GlobalTimerResolutionRequests = 1" -ForegroundColor Green

Log "Module 09 BCDTweaks: Completed"
Write-Host "`n  [OK] BCD tweaks applied. Reboot required.`n" -ForegroundColor Green
