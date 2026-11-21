param(
    [string]$YazxDir,
    [string]$BackupDir,
    [string]$LogFile,
    [switch]$Auto
)

# YAZX Module 14: Advanced Tweaks
# Interactive with YAZX smart defaults — press Enter to apply recommended
# -Auto: applies all YAZX defaults without prompting

. "$PSScriptRoot\YAZX_Common.ps1"

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    YAZX Module 14: Advanced Tweaks" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
if ($Auto) {
    Write-Host "  Mode: AUTO (applying YAZX defaults)" -ForegroundColor Green
} else {
    Write-Host "  Mode: INTERACTIVE (Enter = YAZX default)" -ForegroundColor Yellow
}
Write-Host ""
YAZX-Log $LogFile "Module 14 AdvancedTweaks: Started (Auto=$($Auto.IsPresent))"

# ══════════════════════════════════════
# SECTION A: Always Applied (no choice)
# ══════════════════════════════════════
Write-Host "  --- Always Applied ---" -ForegroundColor Cyan

# A1. VBS / HVCI / Core Isolation
Write-Host "  [A1] VBS / HVCI / Core Isolation" -ForegroundColor Yellow
YAZX-Apply -LogFile $LogFile -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" `
    -Name "EnableVirtualizationBasedSecurity" -Value 0 -Desc "VBS"
YAZX-Apply -LogFile $LogFile -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" `
    -Name "RequirePlatformSecurityFeatures" -Value 0 -Desc "VBS PlatformSecurity"
YAZX-Apply -LogFile $LogFile -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" `
    -Name "Enabled" -Value 0 -Desc "HVCI"
YAZX-Apply -LogFile $LogFile -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" `
    -Name "VulnerableDriverBlocklistEnable" -Value 0 -Desc "Driver Blocklist"

# A2. Audio Optimization
Write-Host ""
Write-Host "  [A2] Audio Optimization" -ForegroundColor Yellow
YAZX-Apply -LogFile $LogFile -Path "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio" `
    -Name "DisableSpatialAudio" -Value 1 -Desc "Spatial Audio"
$devEnum = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
if (Test-Path $devEnum) {
    $audioDevs = 0
    Get-ChildItem $devEnum -ErrorAction SilentlyContinue | ForEach-Object {
        $propPath = "$($_.PSPath)\Properties"
        if (Test-Path $propPath) {
            Set-ItemProperty -Path $propPath -Name "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $audioDevs++
        }
    }
    Write-Host "    [OK] Audio enhancements disabled ($audioDevs devices)" -ForegroundColor Green
    YAZX-Log $LogFile "Audio enhancements: disabled on $audioDevs render devices"
}

# ══════════════════════════════════════
# SECTION B: Smart Defaults (with choices)
# ══════════════════════════════════════
Write-Host ""
Write-Host "  --- Tweaks with Options ---" -ForegroundColor Cyan
Write-Host ""

# B1. Timer Resolution Honoring
Write-Host "  [B1] Timer Resolution" -ForegroundColor Yellow
$timerVal = YAZX-Choose -Title "Timer Resolution Honoring" -Labels @(
    "Enable — honor app timer requests (lowest latency)",
    "Disable — Windows default behavior"
) -Values @(1, 0) -Default 0 -Auto $Auto.IsPresent
YAZX-Apply -LogFile $LogFile `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" `
    -Name "GlobalTimerResolutionRequests" -Value $timerVal -Desc "TimerResolution"

# B2. Large System Cache
Write-Host ""
Write-Host "  [B2] Large System Cache" -ForegroundColor Yellow
$cacheVal = YAZX-Choose -Title "System Cache Priority" -Labels @(
    "0 — Prioritize application memory (gaming)",
    "1 — Prioritize system file cache (server)"
) -Values @(0, 1) -Default 0 -Auto $Auto.IsPresent
YAZX-Apply -LogFile $LogFile `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
    -Name "LargeSystemCache" -Value $cacheVal -Desc "LargeSystemCache"

# B3. Memory Compression
Write-Host ""
Write-Host "  [B3] Memory Compression" -ForegroundColor Yellow
$mcChoice = YAZX-Choose -Title "Memory Compression (16GB+ RAM recommended to disable)" -Labels @(
    "Disable — lower CPU overhead, uses more RAM",
    "Enable — Windows default, compresses idle pages"
) -Values @("disable", "enable") -Default 0 -Auto $Auto.IsPresent
try {
    if ($mcChoice -eq "disable") {
        Disable-MMAgent -MemoryCompression -ErrorAction Stop
        Write-Host "    [OK] Memory Compression = Disabled" -ForegroundColor Green
    } else {
        Enable-MMAgent -MemoryCompression -ErrorAction Stop
        Write-Host "    [OK] Memory Compression = Enabled" -ForegroundColor Green
    }
    YAZX-Log $LogFile "MemoryCompression: $mcChoice"
} catch {
    Write-Host "    [!] Memory Compression: requires admin" -ForegroundColor Yellow
    YAZX-Log $LogFile "MemoryCompression: failed (not admin?)"
}

# B4. Heterogeneous Thread Policy (P-core preference)
Write-Host ""
Write-Host "  [B4] Thread Scheduling Policy (Hybrid CPU)" -ForegroundColor Yellow
$cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue).Name
$isHybrid = $cpu -match "12[0-9]{2}|13[0-9]{2}|14[0-9]{2}|Ultra"
if ($isHybrid) {
    $schedVal = YAZX-Choose -Title "Heterogeneous Thread Policy" -Labels @(
        "4 — Prefer P-cores (best for gaming)",
        "0 — Automatic (Windows decides)",
        "5 — Force P-cores only (aggressive)"
    ) -Values @(4, 0, 5) -Default 0 -Auto $Auto.IsPresent
    powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d $schedVal 2>$null
    powercfg /setactive scheme_current 2>$null
    Write-Host "    [OK] Thread Policy = $schedVal" -ForegroundColor Green
    YAZX-Log $LogFile "ThreadPolicy: set to $schedVal"
} else {
    Write-Host "    [--] Skipped (non-hybrid CPU: $cpu)" -ForegroundColor Gray
    YAZX-Log $LogFile "ThreadPolicy: skipped (non-hybrid CPU)"
}

# B5. PCIe ASPM (Link State Power Management)
Write-Host ""
Write-Host "  [B5] PCIe ASPM" -ForegroundColor Yellow
$aspmVal = YAZX-Choose -Title "PCIe Link State Power Management" -Labels @(
    "0 — Off (lowest latency, more power)",
    "1 — L0s only (light saving)",
    "2 — L1 and L0s (most power saving)"
) -Values @(0, 1, 2) -Default 0 -Auto $Auto.IsPresent
powercfg /setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 $aspmVal 2>$null
powercfg /setactive scheme_current 2>$null
Write-Host "    [OK] PCIe ASPM = $aspmVal" -ForegroundColor Green
YAZX-Log $LogFile "PCIe_ASPM: set to $aspmVal"

# ══════════════════════════════════════
# Summary
# ══════════════════════════════════════
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Module 14 Complete" -ForegroundColor Green
Write-Host "    VBS/HVCI: Off | Audio: Optimized" -ForegroundColor Green
Write-Host "    Timer=$timerVal | Cache=$cacheVal | MC=$mcChoice" -ForegroundColor Green
Write-Host "    Threads=$(if($isHybrid){$schedVal}else{'N/A'}) | ASPM=$aspmVal" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
YAZX-Log $LogFile "Module 14 AdvancedTweaks: Completed (all applied)"
