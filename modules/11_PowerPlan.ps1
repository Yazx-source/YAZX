param($YazxDir, $BackupDir, $LogFile)
# YAZX Module 11 - Power Plan
# Enables Ultimate Performance plan (QuakedK method) and applies YAZX power tweaks

function Log($msg) { "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $msg" | Out-File $LogFile -Append -Encoding UTF8 }

Write-Host "`n  === YAZX Module 11: Power Plan ===" -ForegroundColor Cyan
Log "Module 11 PowerPlan: Started"

# Enable hidden Ultimate Performance scheme (QuakedK approach)
Write-Host "  Checking for existing YAZX power plan..." -ForegroundColor Yellow
$schemes = powercfg /list 2>&1
$existing = $schemes | Select-String "YAZX Ultimate Performance"
if ($existing -and $existing.ToString() -match '([0-9a-f-]{36})') {
    $guid = $Matches[1]
    powercfg /setactive $guid
    Write-Host "  [OK] YAZX Ultimate Performance found and activated" -ForegroundColor Green
    Log "PowerPlan: Activated existing YAZX Ultimate Performance, GUID=$guid"
} else {
    Write-Host "  Creating YAZX Ultimate Performance plan..." -ForegroundColor Yellow
    $dupOutput = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($dupOutput -match '([0-9a-f-]{36})') {
        $guid = $Matches[1]
        powercfg -changename $guid "YAZX Ultimate Performance" "YAZX gaming power plan based on Ultimate Performance"
        powercfg /setactive $guid
        Write-Host "  [OK] YAZX Ultimate Performance created and activated" -ForegroundColor Green
        Log "PowerPlan: Created YAZX Ultimate Performance, GUID=$guid"
    } else {
        $fallback = $schemes | Select-String "Ultimate Performance"
        if ($fallback -and $fallback.ToString() -match '([0-9a-f-]{36})') {
            powercfg /setactive $Matches[1]
            Write-Host "  [OK] Ultimate Performance activated" -ForegroundColor Green
            Log "PowerPlan: Activated existing Ultimate Performance"
        } else {
            Write-Host "  [!] Could not create Ultimate Performance plan" -ForegroundColor Red
            Log "PowerPlan: Failed to create plan"
        }
    }
}

# Disable USB selective suspend
powercfg /setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
# Disable PCI Express Link State Power Management
powercfg /setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null
# Disable Hard disk timeout
powercfg /setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 2>$null
# Disable Modern Standby (PlatformAoAcOverride)
$pwrPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
Set-ItemProperty -Path $pwrPath -Name "PlatformAoAcOverride" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $pwrPath -Name "CsEnabled" -Value 0 -Type DWord -Force
Write-Host "  [OK] Modern Standby disabled (PlatformAoAcOverride=0)" -ForegroundColor Green

# Disable Processor Idle (prevents C-states — lower latency, higher power)
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 5d76a2ca-e8c0-402f-a133-2158492d58ad 1 2>$null

powercfg /setactive scheme_current

Write-Host "  [OK] Power settings optimized" -ForegroundColor Green
Log "Module 11 PowerPlan: Completed (Modern Standby off, Idle off)"
Write-Host "`n  [OK] Power plan module complete.`n" -ForegroundColor Green
