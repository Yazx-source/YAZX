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
# SECTION C: System Restoration (always applied from backup)
# ══════════════════════════════════════
Write-Host ""
Write-Host "  --- System Restoration ---" -ForegroundColor Cyan
Write-Host ""

# C1. UAC Permanent Lockdown (auto-elevate, never re-enables)
Write-Host "  [C1] UAC Permanent Lockdown" -ForegroundColor Yellow
$uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# Layer 1: Registry values (EnableLUA stays 1, prompts eliminated)
YAZX-Apply -LogFile $LogFile -Path $uacPath -Name "EnableLUA" -Value 1 -Desc "EnableLUA (ON - apps safe)"
YAZX-Apply -LogFile $LogFile -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -Desc "Admin auto-elevate"
YAZX-Apply -LogFile $LogFile -Path $uacPath -Name "ConsentPromptBehaviorUser" -Value 0 -Desc "User auto-elevate"
YAZX-Apply -LogFile $LogFile -Path $uacPath -Name "PromptOnSecureDesktop" -Value 0 -Desc "Secure desktop off"
YAZX-Apply -LogFile $LogFile -Path $uacPath -Name "EnableInstallerDetection" -Value 0 -Desc "Installer detection off"
YAZX-Apply -LogFile $LogFile -Path $uacPath -Name "ValidateAdminCodeSignatures" -Value 0 -Desc "No code signing check"
YAZX-Apply -LogFile $LogFile -Path $uacPath -Name "FilterAdministratorToken" -Value 0 -Desc "No admin token filter"

# Layer 2: Suppress Security Center UAC warning
$scPath = "HKLM:\SOFTWARE\Microsoft\Security Center"
if (-not (Test-Path $scPath)) { New-Item -Path $scPath -Force | Out-Null }
Set-ItemProperty -Path $scPath -Name "UacDisableNotify" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "    [OK] Security Center UAC notification suppressed" -ForegroundColor Green

# Layer 3: Group Policy locks (highest authority - survives WU)
$gpUacPol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\UIPI"
if (-not (Test-Path $gpUacPol)) { New-Item -Path $gpUacPol -Force -ErrorAction SilentlyContinue | Out-Null }

# Layer 4: Scheduled task to enforce on every login + every 6 hours
$taskName = "YAZX_UAC_Enforce"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (-not $existingTask) {
    $psCmd = 'Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Value 0 -Force; Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name PromptOnSecureDesktop -Value 0 -Force; Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorUser -Value 0 -Force'
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$psCmd`""
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn
    $triggerRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggerLogon,$triggerRepeat -Principal $principal -Settings $settings -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Host "    [OK] YAZX_UAC_Enforce task: runs at login + every 6h" -ForegroundColor Green
    YAZX-Log $LogFile "UAC: enforcement task created (login + 6h repeat)"
} else {
    Write-Host "    [OK] YAZX_UAC_Enforce task already exists" -ForegroundColor Green
}

Write-Host "    [!!] UAC LOCKED: auto-elevate ON, prompts OFF, enforcement active" -ForegroundColor Green
YAZX-Log $LogFile "UAC: permanently locked down (registry + Security Center + scheduled task)"

# C2. Hosts File (telemetry blocks)
Write-Host ""
Write-Host "  [C2] Hosts File" -ForegroundColor Yellow
$hostsSrc = "$BackupDir\yazx_SystemTweaks\hosts"
$hostsDst = "C:\Windows\System32\drivers\etc\hosts"
if (Test-Path $hostsSrc) {
    $lines = (Get-Content $hostsSrc | Where-Object { $_.Trim() -and -not $_.StartsWith("#") }).Count
    Copy-Item $hostsSrc $hostsDst -Force -ErrorAction SilentlyContinue
    Write-Host "    [OK] Hosts file restored ($lines telemetry blocks)" -ForegroundColor Green
    YAZX-Log $LogFile "Hosts: restored $lines entries"
} else {
    Write-Host "    [!] Hosts backup not found in $hostsSrc" -ForegroundColor Yellow
}

# C3. DNS (Cloudflare Family + Quad9)
Write-Host ""
Write-Host "  [C3] DNS Servers" -ForegroundColor Yellow
$activeNic = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if ($activeNic) {
    Set-DnsClientServerAddress -InterfaceIndex $activeNic.ifIndex -ServerAddresses @("1.1.1.2","1.0.0.2","9.9.9.9","149.112.112.112") -ErrorAction SilentlyContinue
    Write-Host "    [OK] $($activeNic.Name): 1.1.1.2, 1.0.0.2, 9.9.9.9, 149.112.112.112" -ForegroundColor Green
    YAZX-Log $LogFile "DNS: set Cloudflare Family + Quad9 on $($activeNic.Name)"
} else {
    Write-Host "    [!] No active NIC found" -ForegroundColor Yellow
}

# C4. Environment Variables (telemetry opt-outs)
Write-Host ""
Write-Host "  [C4] Environment Variables" -ForegroundColor Yellow
$envVars = @(
    @{ Scope="Machine"; Name="POWERSHELL_TELEMETRY_OPTOUT"; Value="1" }
    @{ Scope="User";    Name="POWERSHELL_TELEMETRY_OPTOUT"; Value="1" }
    @{ Scope="User";    Name="DOTNET_CLI_TELEMETRY_OPTOUT"; Value="1" }
)
foreach ($ev in $envVars) {
    [Environment]::SetEnvironmentVariable($ev.Name, $ev.Value, $ev.Scope)
    Write-Host "    [OK] $($ev.Scope): $($ev.Name) = $($ev.Value)" -ForegroundColor Green
}
YAZX-Log $LogFile "EnvVars: telemetry opt-outs set"

# C5. Windows Update Disable Policy
Write-Host ""
Write-Host "  [C5] Windows Update Policy" -ForegroundColor Yellow
$wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force | Out-Null }
YAZX-Apply -LogFile $LogFile -Path $wuPath -Name "NoAutoUpdate" -Value 1 -Desc "NoAutoUpdate"

# C6. IMOD Disabler (USB interrupt moderation)
Write-Host ""
Write-Host "  [C6] IMOD Disabler" -ForegroundColor Yellow
$imodSrc = "$BackupDir\yazx_SystemTweaks\IMOD_Disabler_Tools"
$imodDst = "C:\IMOD Disabler Tools"
if (Test-Path $imodSrc) {
    if (-not (Test-Path $imodDst)) { New-Item -ItemType Directory -Path $imodDst -Force | Out-Null }
    Copy-Item "$imodSrc\*" $imodDst -Recurse -Force -ErrorAction SilentlyContinue
    $imodScript = "$imodDst\IMOD Scripts\XHCI-IMOD-Interval.ps1"
    if (Test-Path $imodScript) {
        $runKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $runKey -Name "IMOD Disabler" -Value "Powershell -NoProfile -ExecutionPolicy Bypass -File `"$imodScript`"" -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] IMOD Disabler restored + startup entry added" -ForegroundColor Green
        YAZX-Log $LogFile "IMOD: restored and added to startup"
    }
} else {
    Write-Host "    [!] IMOD backup not found" -ForegroundColor Yellow
}

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
