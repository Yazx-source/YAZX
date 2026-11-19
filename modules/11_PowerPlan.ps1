param($YazxDir, $BackupDir, $LogFile)
# YAZX Module 11 - Power Plan
# Imports and activates TTCH Ultimate Performance plan

function Log($msg) { "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $msg" | Out-File $LogFile -Append -Encoding UTF8 }

Write-Host "`n  === YAZX Module 11: Power Plan ===" -ForegroundColor Cyan
Log "Module 11 PowerPlan: Started"

# Try to find the power plan file
$planFile = $null
$locations = @(
    "$YazxDir\configs\active_plan.pow",
    "$BackupDir\yazx_PowerPlans\active_plan.pow",
    "$YazxDir\configs\EonX.pow",
    "$BackupDir\yazx_PowerPlans\EonX.pow"
)
foreach ($loc in $locations) {
    if (Test-Path $loc) { $planFile = $loc; break }
}

if ($planFile) {
    # Import the plan
    $guid = [guid]::NewGuid().ToString()
    $result = powercfg -import $planFile $guid 2>&1
    if ($LASTEXITCODE -eq 0) {
        # Activate it
        powercfg /setactive $guid
        Write-Host "  [OK] Power plan imported and activated" -ForegroundColor Green
        Log "PowerPlan: Imported from $planFile, GUID=$guid"
    } else {
        Write-Host "  [!] Import failed: $result" -ForegroundColor Red
        Log "PowerPlan: Import failed - $result"
    }
} else {
    Write-Host "  [!] No power plan file found" -ForegroundColor Red
    Write-Host "  Enabling built-in Ultimate Performance..." -ForegroundColor Yellow
    # Enable hidden Ultimate Performance scheme
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    $schemes = powercfg /list 2>&1
    $ultPerf = ($schemes | Select-String "Ultimate Performance").ToString()
    if ($ultPerf -match '([0-9a-f-]{36})') {
        powercfg /setactive $Matches[1]
        Write-Host "  [OK] Ultimate Performance activated" -ForegroundColor Green
    }
}

# Disable USB selective suspend
powercfg /setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
# Disable PCI Express Link State Power Management
powercfg /setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null
# Disable Hard disk timeout
powercfg /setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 2>$null
powercfg /setactive scheme_current

Write-Host "  [OK] Power settings optimized" -ForegroundColor Green
Log "Module 11 PowerPlan: Completed"
Write-Host "`n  [OK] Power plan module complete.`n" -ForegroundColor Green
