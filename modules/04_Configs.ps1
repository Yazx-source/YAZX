param($YazxDir, $BackupDir, $LogFile, [switch]$Auto)
# YAZX Module 04 - Restore All Configurations
# Copies config files from backup to correct locations

. "$PSScriptRoot\YAZX_Common.ps1"
function Log($msg) { YAZX-Log $LogFile $msg }

Write-Host "`n  === YAZX Module 04: Configs ===" -ForegroundColor Cyan
Log "Module 04 Configs: Started"

$ok = 0; $skip = 0

# --- Process Lasso ---
Write-Host "  --- Process Lasso Config ---" -ForegroundColor Yellow
$plDst = "C:\ProgramData\ProcessLasso\config"
$plSrc = "$YazxDir\configs\ProcessLasso\prolasso.ini"
if (-not (Test-Path $plSrc)) { $plSrc = "$BackupDir\yazx_ProcessLasso\config\prolasso.ini" }

if (Test-Path $plSrc) {
    New-Item -ItemType Directory -Path $plDst -Force | Out-Null
    Copy-Item $plSrc "$plDst\prolasso.ini" -Force
    Write-Host "  [OK] prolasso.ini (70+ game rules)" -ForegroundColor Green
    Log "ProcessLasso config: Restored"; $ok++
} else { Write-Host "  [!] prolasso.ini not found" -ForegroundColor Red; $skip++ }

# --- MSI Afterburner ---
Write-Host "  --- MSI Afterburner Profiles ---" -ForegroundColor Yellow
$abDst = "C:\Program Files (x86)\MSI Afterburner\Profiles"
$abSrc = "$BackupDir\yazx_MSI_Afterburner\Profiles"
if (-not (Test-Path $abSrc)) { $abSrc = "$YazxDir\exports\MSI_Afterburner" }
if (Test-Path $abSrc) {
    New-Item -ItemType Directory -Path $abDst -Force | Out-Null
    Copy-Item "$abSrc\*" "$abDst\" -Recurse -Force
    Write-Host "  [OK] MSI Afterburner profiles" -ForegroundColor Green
    Log "MSI Afterburner: Profiles restored"; $ok++
} else { Write-Host "  [!] MSI Afterburner profiles not found" -ForegroundColor Red; $skip++ }

# Also copy startup config
$abStartup = "$BackupDir\yazx_MSI_Afterburner\Profiles\MSIAfterburner.cfg"
if (-not (Test-Path $abStartup)) { $abStartup = "$YazxDir\exports\MSI_Afterburner\MSIAfterburner.cfg" }
if (Test-Path $abStartup) {
    Copy-Item $abStartup "$abDst\MSIAfterburner.cfg" -Force
}

# --- Equalizer APO ---
Write-Host "  --- Equalizer APO ---" -ForegroundColor Yellow
$eqDst = "C:\Program Files\EqualizerAPO\config"
$eqSrc = "$BackupDir\yazx_EqualizerAPO\config"
if (-not (Test-Path $eqSrc)) { $eqSrc = "$YazxDir\exports\EqualizerAPO" }
if (Test-Path $eqSrc) {
    New-Item -ItemType Directory -Path $eqDst -Force | Out-Null
    Copy-Item "$eqSrc\*" "$eqDst\" -Recurse -Force
    Write-Host "  [OK] Equalizer APO config" -ForegroundColor Green
    Log "Equalizer APO: Config restored"; $ok++
} else { $skip++ }

# --- NVIDIA Profile Inspector ---
Write-Host "  --- NVIDIA Profile Inspector ---" -ForegroundColor Yellow
$npiProfile = "$YazxDir\configs\NVIDIA_Inspector\Performances.nip"
if (Test-Path $npiProfile) {
    Write-Host "  [OK] YAZX profile ready: Performances.nip" -ForegroundColor Green
    Write-Host "  [!] Import in NVIDIA Profile Inspector manually" -ForegroundColor Yellow
    $ok++
} else { $skip++ }

# --- CRU (Custom Resolution Utility) ---
Write-Host "  --- CRU ---" -ForegroundColor Yellow
$cruSrc = "$YazxDir\configs\CRU"
if (Test-Path "$cruSrc\*.exe") {
    Write-Host "  [OK] CRU files ready in $cruSrc" -ForegroundColor Green
    Write-Host "  [!] Run CRU.exe manually to set custom resolutions" -ForegroundColor Yellow
    $ok++
} else {
    $cruBackup = "$BackupDir\yazx_CRU"
    if (Test-Path $cruBackup) {
        Copy-Item "$cruBackup\*" "$cruSrc\" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] CRU copied from backup" -ForegroundColor Green
        $ok++
    } else { $skip++ }
}

# --- LibreWolf Profile ---
Write-Host "  --- LibreWolf ---" -ForegroundColor Yellow
$lwSrc = "$BackupDir\yazx_LibreWolf"
if (-not (Test-Path $lwSrc)) { $lwSrc = "$YazxDir\configs\LibreWolf" }
if (Test-Path $lwSrc) {
    $lwBase = "C:\Users\$env:USERNAME\AppData\Roaming\librewolf"
    $lwProfiles = "$lwBase\Profiles"
    if (Test-Path $lwProfiles) {
        $defaultProfile = $null
        $iniPath = "$lwBase\profiles.ini"
        if (Test-Path $iniPath) {
            $iniContent = Get-Content $iniPath -Raw
            if ($iniContent -match '(?m)Path=Profiles[/\\]([^\r\n]+)') {
                $profName = $Matches[1]
                $profPath = Join-Path $lwProfiles $profName
                if (Test-Path $profPath) { $defaultProfile = Get-Item $profPath }
            }
        }
        if (-not $defaultProfile) {
            $defaultProfile = Get-ChildItem $lwProfiles -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
        if ($defaultProfile) {
            Copy-Item "$lwSrc\prefs.js" "$($defaultProfile.FullName)\prefs.js" -Force -ErrorAction SilentlyContinue
            Copy-Item "$lwSrc\user.js" "$($defaultProfile.FullName)\user.js" -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] LibreWolf prefs restored" -ForegroundColor Green
            $ok++
        }
    } else {
        Write-Host "  [!] LibreWolf not installed yet - run after installing LibreWolf" -ForegroundColor Yellow
        $skip++
    }
} else { $skip++ }

# --- ExplorerPatcher ---
Write-Host "  --- ExplorerPatcher ---" -ForegroundColor Yellow
$epReg = "$BackupDir\yazx_ExplorerPatcher\ExplorerPatcher_HKCU.reg"
if (-not (Test-Path $epReg)) { $epReg = "$YazxDir\exports\ExplorerPatcher\ExplorerPatcher_HKCU.reg" }
if (Test-Path $epReg) {
    regedit /s $epReg
    Write-Host "  [OK] ExplorerPatcher settings imported" -ForegroundColor Green
    Log "ExplorerPatcher: Registry imported"; $ok++
} else { $skip++ }

# --- Steam Config ---
Write-Host "  --- Steam ---" -ForegroundColor Yellow
$stDst = "C:\Program Files (x86)\Steam\config"
$stSrc = "$BackupDir\yazx_SteamConfig"
if (-not (Test-Path $stSrc)) { $stSrc = "$YazxDir\exports\Steam" }
if ((Test-Path $stSrc) -and (Test-Path "C:\Program Files (x86)\Steam")) {
    New-Item -ItemType Directory -Path $stDst -Force | Out-Null
    Copy-Item "$stSrc\config.vdf" "$stDst\" -Force -ErrorAction SilentlyContinue
    Copy-Item "$stSrc\DialogConfig.vdf" "$stDst\" -Force -ErrorAction SilentlyContinue
    Copy-Item "$stSrc\loginusers.vdf" "$stDst\" -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Steam config restored" -ForegroundColor Green
    Log "Steam: Config restored"; $ok++
} else { $skip++ }

# --- Timer Resolution Service ---
Write-Host "  --- Timer Resolution Service ---" -ForegroundColor Yellow
$trSrc = "$YazxDir\configs\TimerResolution\SetTimerResolutionService.exe"
if (-not (Test-Path $trSrc)) { $trSrc = "$BackupDir\yazx_TimerResolution\SetTimerResolutionService.exe" }
if (Test-Path $trSrc) {
    $expectedHash = "004CB6E0FB1A27CD676582DE32EA26FD901BC35ADCAB06511A3475EDDBDFB0FE"
    $actualHash = (Get-FileHash $trSrc -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        Write-Host "  [!!] SetTimerResolutionService.exe SHA-256 MISMATCH - skipped" -ForegroundColor Red
        Write-Host "  Expected: $expectedHash" -ForegroundColor Red
        Write-Host "  Got:      $actualHash" -ForegroundColor Red
        Log "SECURITY: TimerResolution binary hash mismatch - skipped"
        $skip++
    } else {
        $trDst = "C:\TTCH_TimerResolution"
        New-Item -ItemType Directory -Path $trDst -Force | Out-Null
        Copy-Item $trSrc "$trDst\SetTimerResolutionService.exe" -Force
        $existingSvc = Get-Service "STR" -ErrorAction SilentlyContinue
        if (-not $existingSvc) {
            sc.exe create "STR" binPath= "`"$trDst\SetTimerResolutionService.exe`"" start= auto 2>$null | Out-Null
            Write-Host "  [OK] Timer Resolution Service created (hash verified)" -ForegroundColor Green
        } else {
            Write-Host "  [OK] Timer Resolution Service already exists" -ForegroundColor Green
        }
        sc.exe start "STR" 2>$null | Out-Null
        Log "TimerResolution: Service installed (SHA-256 verified)"; $ok++
    }
} else { $skip++ }

# --- Open Shell ---
Write-Host "  --- Open Shell ---" -ForegroundColor Yellow
$osSrc = "$BackupDir\yazx_OpenShell"
if (-not (Test-Path $osSrc)) { $osSrc = "$YazxDir\exports\OpenShell" }
if (Test-Path $osSrc) {
    $osMenuXml = Get-ChildItem $osSrc -Filter "*.xml" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($osMenuXml) {
        Write-Host "  [OK] Open Shell config available: $($osMenuXml.Name)" -ForegroundColor Green
        Write-Host "  [!] Import in Open Shell Settings manually" -ForegroundColor Yellow
        $ok++
    }
} else { $skip++ }

# --- Power Plan ---
Write-Host "  --- Power Plan ---" -ForegroundColor Yellow
$ppSrc = "$YazxDir\configs\active_plan.pow"
if (-not (Test-Path $ppSrc)) { $ppSrc = "$BackupDir\yazx_PowerPlans\active_plan.pow" }
if (Test-Path $ppSrc) {
    powercfg -import $ppSrc 2>$null
    Write-Host "  [OK] Power plan imported (activate in module 11)" -ForegroundColor Green
    $ok++
} else { $skip++ }

Write-Host "`n  Summary: $ok restored, $skip skipped" -ForegroundColor Cyan
Log "Module 04 Configs: $ok restored, $skip skipped. Completed"
Write-Host "  [OK] Configs module complete.`n" -ForegroundColor Green
