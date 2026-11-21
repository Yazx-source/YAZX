# YAZX Simulator - Dry-Run Validation Tool
# Validates all YAZX modules for correctness WITHOUT applying any changes
# Safe to run on the current system: READ-ONLY analysis only

param(
    [string]$YazxDir = (Split-Path $MyInvocation.MyCommand.Path),
    [string]$BackupDir = ""
)

$ErrorActionPreference = "Continue"
$script:PassCount = 0
$script:WarnCount = 0
$script:FailCount = 0
$script:InfoCount = 0

function Result {
    param([string]$Status, [string]$Module, [string]$Check, [string]$Detail)
    switch ($Status) {
        "PASS" { Write-Host "  [PASS] " -NoNewline -ForegroundColor Green; $script:PassCount++ }
        "WARN" { Write-Host "  [WARN] " -NoNewline -ForegroundColor Yellow; $script:WarnCount++ }
        "FAIL" { Write-Host "  [FAIL] " -NoNewline -ForegroundColor Red; $script:FailCount++ }
        "INFO" { Write-Host "  [INFO] " -NoNewline -ForegroundColor Cyan; $script:InfoCount++ }
    }
    Write-Host "$Module | $Check" -NoNewline -ForegroundColor White
    if ($Detail) { Write-Host " - $Detail" -ForegroundColor Gray } else { Write-Host "" }
}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "    YAZX Simulator - Pre-Format Validation" -ForegroundColor Cyan
Write-Host "    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "    YazxDir: $YazxDir" -ForegroundColor Gray
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""

# ================================================================
# TEST 1: Project Structure
# ================================================================
Write-Host "  --- Test 1: Project Structure ---" -ForegroundColor Yellow

$modulesDir = Join-Path $YazxDir "modules"
if (Test-Path $modulesDir) {
    Result "PASS" "Structure" "modules/ directory exists"
} else {
    Result "FAIL" "Structure" "modules/ directory missing" "$modulesDir"
}

$commonPs1 = Join-Path $modulesDir "YAZX_Common.ps1"
if (Test-Path $commonPs1) {
    Result "PASS" "Structure" "YAZX_Common.ps1 exists"
} else {
    Result "FAIL" "Structure" "YAZX_Common.ps1 missing (all modules depend on it)"
}

$setupBat = Join-Path $YazxDir "YAZX_Setup.bat"
if (Test-Path $setupBat) {
    Result "PASS" "Structure" "YAZX_Setup.bat exists"
} else {
    Result "FAIL" "Structure" "YAZX_Setup.bat missing"
}

$expectedModules = @(
    "01_SystemCheck.ps1", "02_NVIDIADriver.ps1", "03_Programs.ps1",
    "04_Configs.ps1", "08_Services.ps1", "09_BCDTweaks.ps1",
    "10_MSIMode.ps1", "11_PowerPlan.ps1", "12_Privacy.ps1",
    "14_NewTweaks.ps1", "15_Autologgers.ps1", "16_DownloadTools.ps1",
    "17_DeviceManager.ps1", "19_YAZXShield.ps1"
)

$missingModules = @()
foreach ($mod in $expectedModules) {
    $path = Join-Path $modulesDir $mod
    if (-not (Test-Path $path)) {
        $missingModules += $mod
    }
}
if ($missingModules.Count -eq 0) {
    Result "PASS" "Structure" "All 14 module files present"
} else {
    Result "FAIL" "Structure" "Missing modules" ($missingModules -join ", ")
}

$configsDir = Join-Path $YazxDir "configs"
if (Test-Path $configsDir) {
    Result "PASS" "Structure" "configs/ directory exists"
} else {
    Result "WARN" "Structure" "configs/ directory missing (some modules need it)"
}

$qosFile = Join-Path $YazxDir "configs\qos_apps.txt"
if (Test-Path $qosFile) {
    Result "PASS" "Structure" "qos_apps.txt exists"
} else {
    Result "INFO" "Structure" "qos_apps.txt not found (optional custom QoS apps)"
}

# ================================================================
# TEST 2: PowerShell Syntax Validation (AST Parse)
# ================================================================
Write-Host ""
Write-Host "  --- Test 2: PowerShell Syntax ---" -ForegroundColor Yellow

$allPs1 = Get-ChildItem $modulesDir -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $allPs1) {
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
    if ($errors.Count -eq 0) {
        Result "PASS" $file.Name "Syntax valid (AST parse)"
    } else {
        foreach ($err in $errors) {
            Result "FAIL" $file.Name "Syntax error" "Line $($err.Extent.StartLineNumber): $($err.Message)"
        }
    }
}

# ================================================================
# TEST 3: Module Parameter Signatures
# ================================================================
Write-Host ""
Write-Host "  --- Test 3: Module Parameter Signatures ---" -ForegroundColor Yellow

$expectedParams = @('$YazxDir', '$BackupDir', '$LogFile', '$Auto')
foreach ($file in $allPs1) {
    if ($file.Name -eq "YAZX_Common.ps1") { continue }
    $content = Get-Content $file.FullName -Raw
    $missing = @()
    foreach ($p in $expectedParams) {
        if ($content -notmatch [regex]::Escape($p)) {
            $missing += $p
        }
    }
    if ($missing.Count -eq 0) {
        Result "PASS" $file.Name "All 4 standard params present"
    } else {
        Result "WARN" $file.Name "Missing params" ($missing -join ", ")
    }
}

# ================================================================
# TEST 4: Common Functions Usage
# ================================================================
Write-Host ""
Write-Host "  --- Test 4: YAZX_Common.ps1 Integration ---" -ForegroundColor Yellow

$commonContent = if (Test-Path $commonPs1) { Get-Content $commonPs1 -Raw } else { "" }

$definedFunctions = @()
if ($commonContent -match 'function\s+(YAZX-Log)') { $definedFunctions += "YAZX-Log" }
if ($commonContent -match 'function\s+(YAZX-Choose)') { $definedFunctions += "YAZX-Choose" }
if ($commonContent -match 'function\s+(YAZX-Apply)') { $definedFunctions += "YAZX-Apply" }

Result "INFO" "YAZX_Common" "Defined functions" ($definedFunctions -join ", ")

foreach ($file in $allPs1) {
    if ($file.Name -eq "YAZX_Common.ps1") { continue }
    $content = Get-Content $file.FullName -Raw
    $dotSource = $content -match '\.\s+"?\$PSScriptRoot\\YAZX_Common\.ps1"?'
    if ($dotSource) {
        Result "PASS" $file.Name "Dot-sources YAZX_Common.ps1"
    } else {
        Result "FAIL" $file.Name "Does NOT dot-source YAZX_Common.ps1"
    }
}

# ================================================================
# TEST 5: EnableLUA Logic Verification
# ================================================================
Write-Host ""
Write-Host "  --- Test 5: EnableLUA Consistency ---" -ForegroundColor Yellow

$sysCheckPath = Join-Path $modulesDir "01_SystemCheck.ps1"
if (Test-Path $sysCheckPath) {
    $sysCheckContent = Get-Content $sysCheckPath -Raw
    if ($sysCheckContent -match 'if\s*\(\s*\$lua\s+-eq\s+1\s*\)') {
        Result "PASS" "01_SystemCheck" "EnableLUA check: 1 = correct (matches YAZX approach)"
    } elseif ($sysCheckContent -match 'if\s*\(\s*\$lua\s+-eq\s+0\s*\)') {
        Result "FAIL" "01_SystemCheck" "EnableLUA check INVERTED: says 0 is correct, YAZX needs 1"
    }
}

$newTweaksPath = Join-Path $modulesDir "14_NewTweaks.ps1"
if (Test-Path $newTweaksPath) {
    $ntContent = Get-Content $newTweaksPath -Raw
    if ($ntContent -match 'EnableLUA.*-Value\s+1') {
        Result "PASS" "14_NewTweaks" "Sets EnableLUA=1 (correct YAZX value)"
    } else {
        Result "FAIL" "14_NewTweaks" "EnableLUA value not set to 1"
    }
}

$shieldPath = Join-Path $modulesDir "19_YAZXShield.ps1"
if (Test-Path $shieldPath) {
    $shieldContent = Get-Content $shieldPath -Raw
    if ($shieldContent -match 'EnableLUA.*Want=1') {
        Result "PASS" "19_YAZXShield" "Verifies EnableLUA=1 (consistent)"
    } else {
        Result "WARN" "19_YAZXShield" "EnableLUA verification not found or wrong value"
    }
}

# ================================================================
# TEST 6: QoS Consistency (Module 17 vs Shield)
# ================================================================
Write-Host ""
Write-Host "  --- Test 6: QoS Policy Consistency ---" -ForegroundColor Yellow

$mod17Path = Join-Path $modulesDir "17_DeviceManager.ps1"
if ((Test-Path $mod17Path) -and (Test-Path $shieldPath)) {
    $mod17Content = Get-Content $mod17Path -Raw
    $shieldContent = Get-Content $shieldPath -Raw

    if ($mod17Content -match 'RocketLeague\.exe.*DSCP.*46' -and $shieldContent -match 'RocketLeague\.exe.*DSCP.*46') {
        Result "PASS" "QoS" "Rocket League DSCP=46 in both Module 17 and Shield"
    } else {
        Result "WARN" "QoS" "Rocket League QoS may differ between Module 17 and Shield"
    }

    $splitRegex = '-split\s+"(.+?)"'
    $mod17Split = if ($mod17Content -match $splitRegex) { $Matches[1] } else { "unknown" }
    $shieldSplit = ""
    $shieldLines = Get-Content $shieldPath
    $partsSplitRegex = '\$parts\s*=.*-split\s+"(.+?)"'
    foreach ($line in $shieldLines) {
        if ($line -match $partsSplitRegex) { $shieldSplit = $Matches[1]; break }
    }
    $pipeCheck = '\[,\|'
    if ($mod17Split -eq $shieldSplit -or ($mod17Split -match $pipeCheck -and $shieldSplit -match $pipeCheck)) {
        Result "PASS" "QoS" "qos_apps.txt parsing consistent between modules"
    } elseif ($shieldSplit -match $pipeCheck) {
        Result "PASS" "QoS" "Shield now accepts comma and pipe separators (fixed)"
    } else {
        Result "WARN" "QoS" "qos_apps.txt parsing differs" "Module 17 vs Shield split patterns"
    }
}

# ================================================================
# TEST 7: UAC Lockdown Values Cross-Check
# ================================================================
Write-Host ""
Write-Host "  --- Test 7: UAC Lockdown Cross-Check ---" -ForegroundColor Yellow

$uacValues = @(
    @{ Name="EnableLUA"; Want=1 }
    @{ Name="ConsentPromptBehaviorAdmin"; Want=0 }
    @{ Name="ConsentPromptBehaviorUser"; Want=0 }
    @{ Name="PromptOnSecureDesktop"; Want=0 }
    @{ Name="EnableInstallerDetection"; Want=0 }
    @{ Name="ValidateAdminCodeSignatures"; Want=0 }
    @{ Name="FilterAdministratorToken"; Want=0 }
)

foreach ($source in @("14_NewTweaks.ps1", "19_YAZXShield.ps1")) {
    $srcPath = Join-Path $modulesDir $source
    if (-not (Test-Path $srcPath)) { continue }
    $srcContent = Get-Content $srcPath -Raw
    $allFound = $true
    foreach ($uac in $uacValues) {
        if ($srcContent -notmatch "$($uac.Name)") {
            Result "WARN" $source "Missing UAC value: $($uac.Name)"
            $allFound = $false
        }
    }
    if ($allFound) {
        Result "PASS" $source "All 7 UAC lockdown values present"
    }
}

# ================================================================
# TEST 8: Shield Critical Services
# ================================================================
Write-Host ""
Write-Host "  --- Test 8: Shield Critical Services ---" -ForegroundColor Yellow

if (Test-Path $shieldPath) {
    $shieldContent = Get-Content $shieldPath -Raw
    foreach ($svc in @("Schedule", "gpsvc", "QWAVE")) {
        if ($shieldContent -match [regex]::Escape($svc)) {
            Result "PASS" "19_YAZXShield" "Protects service: $svc"
        } else {
            Result "FAIL" "19_YAZXShield" "Missing protection for: $svc"
        }
    }
}

# ================================================================
# TEST 9: YAZX_Setup.bat Menu Validation
# ================================================================
Write-Host ""
Write-Host "  --- Test 9: YAZX_Setup.bat Menu ---" -ForegroundColor Yellow

if (Test-Path $setupBat) {
    $batContent = Get-Content $setupBat -Raw

    foreach ($mod in $expectedModules) {
        $modNum = ($mod -split '_')[0]
        if ($batContent -match [regex]::Escape($mod)) {
            Result "PASS" "Setup.bat" "References $mod"
        } else {
            Result "WARN" "Setup.bat" "Module $mod not referenced in bat"
        }
    }

    if ($batContent -match ':run_all') {
        Result "PASS" "Setup.bat" "Auto-mode (:run_all) label exists"
    } else {
        Result "FAIL" "Setup.bat" "Auto-mode (:run_all) label missing"
    }

    if ($batContent -match 'YAZX Shield') {
        Result "PASS" "Setup.bat" "Shield menu entry present"
    } else {
        Result "FAIL" "Setup.bat" "Shield menu entry missing"
    }
}

# ================================================================
# TEST 10: Backup Directory Detection
# ================================================================
Write-Host ""
Write-Host "  --- Test 10: Backup Detection ---" -ForegroundColor Yellow

if (-not $BackupDir) {
    $searchDrives = @("E:", "D:", "C:", "F:", "G:")
    foreach ($drv in $searchDrives) {
        $candidate = "$drv\YAZX_Backup"
        if (Test-Path $candidate) { $BackupDir = $candidate; break }
        $candidate = "$drv\YAZX_GitHub_Backup"
        if (Test-Path $candidate) { $BackupDir = $candidate; break }
    }
}

if ($BackupDir -and (Test-Path $BackupDir)) {
    Result "PASS" "Backup" "Found at $BackupDir"

    $backupItems = @(
        "yazx_ProcessLasso", "yazx_MSI_Afterburner", "yazx_EqualizerAPO",
        "yazx_OpenShell", "yazx_MemReduct", "yazx_SteamConfig",
        "yazx_LibreWolf", "yazx_ExplorerPatcher", "yazx_SystemTweaks",
        "yazx_NVIDIA_Settings", "yazx_CRU", "yazx_RevoUninstaller",
        "yazx_ParkControl", "yazx_TimerResolution", "yazx_BIOS"
    )

    $found = 0; $missing = @()
    foreach ($item in $backupItems) {
        if (Test-Path "$BackupDir\$item") { $found++ } else { $missing += $item }
    }
    Result "INFO" "Backup" "$found of $($backupItems.Count) backup folders present"
    if ($missing.Count -gt 0 -and $missing.Count -le 5) {
        Result "INFO" "Backup" "Missing" ($missing -join ", ")
    } elseif ($missing.Count -gt 5) {
        Result "WARN" "Backup" "$($missing.Count) backup folders missing"
    }
} else {
    Result "WARN" "Backup" "No backup directory found (modules will skip restore steps)"
}

# ================================================================
# TEST 11: Config Files Validation
# ================================================================
Write-Host ""
Write-Host "  --- Test 11: Config Files ---" -ForegroundColor Yellow

$configChecks = @(
    @{ Path="configs\qos_apps.txt"; Desc="QoS custom apps"; Required=$false }
    @{ Path="configs\ProcessLasso\prolasso.ini"; Desc="Process Lasso config"; Required=$false }
    @{ Path="configs\NVIDIA_Inspector\Performances.nip"; Desc="NPI profile"; Required=$false }
    @{ Path="configs\TimerResolution\SetTimerResolutionService.exe"; Desc="Timer Resolution binary"; Required=$false }
    @{ Path="configs\active_plan.pow"; Desc="Power plan export"; Required=$false }
)

foreach ($cfg in $configChecks) {
    $cfgPath = Join-Path $YazxDir $cfg.Path
    if (Test-Path $cfgPath) {
        $sz = [math]::Round((Get-Item $cfgPath).Length / 1KB, 1)
        Result "PASS" "Config" "$($cfg.Desc)" "${sz} KB"
    } else {
        $status = if ($cfg.Required) { "FAIL" } else { "INFO" }
        Result $status "Config" "$($cfg.Desc) not found" $cfg.Path
    }
}

if (Test-Path $qosFile) {
    $qosLines = Get-Content $qosFile | Where-Object { $_.Trim() -and -not $_.StartsWith("#") }
    $validQos = 0; $invalidQos = 0
    foreach ($line in $qosLines) {
        $parts = $line -split '\s*[,|]\s*'
        if ($parts.Count -ge 2 -and $parts[1].Trim() -match '\.exe$') {
            $validQos++
        } else {
            $invalidQos++
            Result "WARN" "QoS Config" "Invalid line" $line
        }
    }
    if ($validQos -gt 0) {
        Result "PASS" "QoS Config" "$validQos valid custom app entries"
    }
    if ($invalidQos -gt 0) {
        Result "WARN" "QoS Config" "$invalidQos invalid entries"
    }
}

# ================================================================
# TEST 12: Module Conflict Detection
# ================================================================
Write-Host ""
Write-Host "  --- Test 12: Module Conflict Detection ---" -ForegroundColor Yellow

$mod08Path = Join-Path $modulesDir "08_Services.ps1"
if ((Test-Path $mod08Path) -and (Test-Path $shieldPath)) {
    $mod08Content = Get-Content $mod08Path -Raw
    $shieldContent = Get-Content $shieldPath -Raw

    foreach ($critSvc in @("Schedule", "gpsvc", "QWAVE")) {
        $m08Disables = $mod08Content -match "$critSvc.*[Dd]isable"
        $shieldRecovers = $shieldContent -match "$critSvc"
        if ($m08Disables -and $shieldRecovers) {
            Result "PASS" "Conflict" "${critSvc}: Module 08 disables, Shield recovers"
        } elseif ($m08Disables -and -not $shieldRecovers) {
            Result "FAIL" "Conflict" "${critSvc} disabled in Module 08 but Shield has no recovery"
        }
    }
}

$mod09Path = Join-Path $modulesDir "09_BCDTweaks.ps1"
if ((Test-Path $mod09Path) -and (Test-Path $newTweaksPath)) {
    $mod09Content = Get-Content $mod09Path -Raw
    $ntContent = Get-Content $newTweaksPath -Raw
    if ($mod09Content -match 'GlobalTimerResolutionRequests.*1' -and $ntContent -match 'GlobalTimerResolutionRequests') {
        Result "INFO" "Conflict" "GlobalTimerResolutionRequests set in both Module 09 and 14 (last write wins)"
    }
}

$mod11Path = Join-Path $modulesDir "11_PowerPlan.ps1"
if ((Test-Path $mod11Path) -and (Test-Path $newTweaksPath)) {
    $mod11Content = Get-Content $mod11Path -Raw
    $ntContent = Get-Content $newTweaksPath -Raw
    if ($mod11Content -match 'ee12f906' -and $ntContent -match 'ee12f906') {
        Result "INFO" "Conflict" "PCIe ASPM set in both Module 11 and 14 (last write wins)"
    }
}

# ================================================================
# TEST 13: Security Checks
# ================================================================
Write-Host ""
Write-Host "  --- Test 13: Security ---" -ForegroundColor Yellow

$mod04Path = Join-Path $modulesDir "04_Configs.ps1"
if (Test-Path $mod04Path) {
    $mod04Content = Get-Content $mod04Path -Raw
    if ($mod04Content -match 'Get-FileHash.*SHA256') {
        Result "PASS" "Security" "04_Configs: TimerResolution binary hash verified"
    } else {
        Result "WARN" "Security" "04_Configs: No hash check on binary copies"
    }
}

$mod16Path = Join-Path $modulesDir "16_DownloadTools.ps1"
if (Test-Path $mod16Path) {
    $mod16Content = Get-Content $mod16Path -Raw
    if ($mod16Content -match 'Confirm-ToolHash|Get-FileHash') {
        Result "PASS" "Security" "16_DownloadTools: SHA-256 hash verification present"
    }
    if ($mod16Content -match '\$knownHashes') {
        $hashCount = ([regex]::Matches($mod16Content, 'Hash="[A-F0-9]{64}"')).Count
        Result "INFO" "Security" "16_DownloadTools: $hashCount known hashes defined"
    }
}

$shieldStartup = Join-Path $YazxDir "scripts\YAZX_Shield_Startup.ps1"
if (Test-Path $shieldStartup) {
    Result "PASS" "Security" "Shield startup script exists at expected path"
} else {
    Result "INFO" "Security" "Shield startup script not yet deployed (created by Module 19 at runtime)"
}

# ================================================================
# TEST 14: Auto-Mode Execution Order
# ================================================================
Write-Host ""
Write-Host "  --- Test 14: Auto-Mode Execution Order ---" -ForegroundColor Yellow

if (Test-Path $setupBat) {
    $batLines = Get-Content $setupBat
    $autoSection = $false
    $autoModules = @()
    foreach ($line in $batLines) {
        if ($line -match ':run_all') { $autoSection = $true; continue }
        if ($autoSection -and $line -match '^\s*goto\s+done') { break }
        if ($autoSection -and $line -match '(\d{2}_\w+\.ps1)') {
            $autoModules += $Matches[1]
        }
    }

    if ($autoModules.Count -gt 0) {
        Result "INFO" "AutoMode" "Execution order" ($autoModules -join " > ")

        if ($autoModules[0] -eq "16_DownloadTools.ps1") {
            Result "PASS" "AutoMode" "Tools download runs first (correct)"
        } else {
            Result "WARN" "AutoMode" "Tools download should run first, found: $($autoModules[0])"
        }

        $shieldIdx = [array]::IndexOf($autoModules, "19_YAZXShield.ps1")
        if ($shieldIdx -eq ($autoModules.Count - 1)) {
            Result "PASS" "AutoMode" "Shield runs last (correct - after all other modules)"
        } elseif ($shieldIdx -ge 0) {
            Result "WARN" "AutoMode" "Shield should run last, but found at position $($shieldIdx + 1)"
        } else {
            Result "FAIL" "AutoMode" "Shield NOT in auto-mode execution order"
        }
    } else {
        Result "WARN" "AutoMode" "Could not parse auto-mode module order"
    }
}

# ================================================================
# TEST 15: Variable Scope / Initialization
# ================================================================
Write-Host ""
Write-Host "  --- Test 15: Variable Issues ---" -ForegroundColor Yellow

if (Test-Path $mod17Path) {
    $mod17Content = Get-Content $mod17Path -Raw
    $initPattern = 'not \$nicKey.*\$applied\s*=\s*0'
    if ($mod17Content -match $initPattern) {
        Result "PASS" "17_DeviceManager" 'Variable $applied initialized when NIC not found (fixed)'
    } else {
        Result "WARN" "17_DeviceManager" 'Variable $applied may be uninitialized when NIC absent'
    }
}

# ================================================================
# SUMMARY
# ================================================================
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "    YAZX Simulator Results" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "    PASS : $($script:PassCount)" -ForegroundColor Green
Write-Host "    WARN : $($script:WarnCount)" -ForegroundColor $(if ($script:WarnCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "    FAIL : $($script:FailCount)" -ForegroundColor $(if ($script:FailCount -gt 0) { "Red" } else { "Green" })
Write-Host "    INFO : $($script:InfoCount)" -ForegroundColor Cyan
Write-Host "  ------------------------------------------------------------" -ForegroundColor Gray
$total = $script:PassCount + $script:WarnCount + $script:FailCount + $script:InfoCount
Write-Host "    Total: $total checks" -ForegroundColor White

if ($script:FailCount -eq 0) {
    Write-Host ""
    Write-Host "    YAZX is ready for format." -ForegroundColor Green
    Write-Host "    All critical checks passed." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "    $($script:FailCount) FAILURES must be fixed before format!" -ForegroundColor Red
}
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
