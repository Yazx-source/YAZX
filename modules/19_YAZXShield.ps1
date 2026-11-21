param(
    [string]$YazxDir,
    [string]$BackupDir,
    [string]$LogFile,
    [switch]$Auto
)

# YAZX Module 19: YAZX Shield (Post-Oneclick Protection)
# Re-applies YAZX tweaks that Oneclick Process Destroyer breaks
# Safe to run multiple times — idempotent
# Keeps ALL Oneclick benefits, only fixes what conflicts with YAZX

. "$PSScriptRoot\YAZX_Common.ps1"
function Log($msg) { YAZX-Log $LogFile $msg }

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    YAZX Module 19: YAZX Shield" -ForegroundColor Cyan
Write-Host "    Post-Oneclick Conflict Protection" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Log "Module 19 YAZXShield: Started"

$fixed = 0

# ================================================================
# Phase 1: Re-enable Critical Services that Oneclick PD kills
# ================================================================
# Oneclick Process Destroyer disables Schedule (Task Scheduler),
# gpsvc (Group Policy Client), and QWAVE (QoS engine).
# These are needed for: UAC enforce task, QoS network priority,
# and Group Policy-based settings.

Write-Host "  --- Phase 1: Critical Service Recovery ---" -ForegroundColor Yellow

$criticalServices = @(
    @{ Name="Schedule";  Desc="Task Scheduler (YAZX UAC enforce + future tasks)"; Start=2 }
    @{ Name="gpsvc";     Desc="Group Policy Client (QoS policies)";               Start=2 }
    @{ Name="QWAVE";     Desc="QoS engine (DSCP network priority)";               Start=3 }
)

foreach ($svc in $criticalServices) {
    $currentStart = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Name)" -Name Start -ErrorAction SilentlyContinue).Start
    if ($currentStart -eq 4) {
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Name)" -Name Start -Value $svc.Start -Force -ErrorAction SilentlyContinue
        $startType = if ($svc.Start -eq 2) { "Automatic" } else { "Manual" }
        Write-Host "  [FIXED] $($svc.Name) = $startType (was disabled by Oneclick PD)" -ForegroundColor Green
        Log "Shield: Re-enabled $($svc.Name) ($($svc.Desc))"
        $fixed++

        $s = Get-Service $svc.Name -ErrorAction SilentlyContinue
        if ($s -and $s.Status -ne 'Running' -and $svc.Start -eq 2) {
            Start-Service $svc.Name -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "  [OK] $($svc.Name) already OK (Start=$currentStart)" -ForegroundColor DarkGray
    }
}

# ================================================================
# Phase 2: Re-create YAZX Scheduled Tasks (Task Destroyer deletes ALL)
# ================================================================
# Oneclick Task Destroyer V1.3 deletes every task in Task Scheduler
# AND deletes the System32\Tasks folder. This kills YAZX_UAC_Enforce.

Write-Host ""
Write-Host "  --- Phase 2: Scheduled Task Recovery ---" -ForegroundColor Yellow

# 2a. UAC Enforce Task
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
    Write-Host "  [FIXED] $taskName re-created (was deleted by Task Destroyer)" -ForegroundColor Green
    Log "Shield: Re-created $taskName scheduled task"
    $fixed++
} else {
    Write-Host "  [OK] $taskName exists" -ForegroundColor DarkGray
}

# ================================================================
# Phase 3: Re-apply QoS Network Priority Policies
# ================================================================
# gpsvc being disabled causes QoS policies to not apply.
# After re-enabling gpsvc, re-create the QoS policies.

Write-Host ""
Write-Host "  --- Phase 3: QoS Policy Recovery ---" -ForegroundColor Yellow

$qosPolicies = @(
    @{ Name="YAZX - Rocket League"; App="RocketLeague.exe"; DSCP=46 }
)

# Also read custom apps from config
$customQosFile = "$YazxDir\configs\qos_apps.txt"
if (Test-Path $customQosFile) {
    $customLines = Get-Content $customQosFile -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -and -not $_.StartsWith("#") }
    foreach ($line in $customLines) {
        $parts = $line -split "\s*[,|]\s*"
        if ($parts.Count -ge 2) {
            $dscp = if ($parts.Count -ge 3) { [int]$parts[2].Trim() } else { 46 }
            $qosPolicies += @{ Name="YAZX - $($parts[0].Trim())"; App=$parts[1].Trim(); DSCP=$dscp }
        }
    }
}

$qosFixed = 0
foreach ($qos in $qosPolicies) {
    $existing = Get-NetQosPolicy -Name $qos.Name -PolicyStore localhost -ErrorAction SilentlyContinue
    if (-not $existing) {
        try {
            New-NetQosPolicy -Name $qos.Name -AppPathNameMatchCondition $qos.App -DSCPAction $qos.DSCP -PolicyStore localhost -ErrorAction Stop | Out-Null
            $dscpLabel = if ($qos.DSCP -eq 46) { "EF (Highest)" } elseif ($qos.DSCP -eq 34) { "AF41 (High)" } else { "$($qos.DSCP)" }
            Write-Host "  [FIXED] $($qos.App) = DSCP $($qos.DSCP) ($dscpLabel)" -ForegroundColor Green
            $qosFixed++
            $fixed++
        } catch {
            Write-Host "  [!] QoS failed: $($qos.Name) - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [OK] $($qos.Name) already exists" -ForegroundColor DarkGray
    }
}
Log "Shield: QoS policies checked ($qosFixed re-created)"

# ================================================================
# Phase 4: Re-apply UAC Lockdown Values
# ================================================================
# Oneclick or Windows Updates may reset UAC values.

Write-Host ""
Write-Host "  --- Phase 4: UAC Lockdown Verification ---" -ForegroundColor Yellow

$uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$uacChecks = @(
    @{ Name="EnableLUA";                   Want=1; Desc="EnableLUA (ON - apps safe)" }
    @{ Name="ConsentPromptBehaviorAdmin";  Want=0; Desc="Admin auto-elevate" }
    @{ Name="ConsentPromptBehaviorUser";   Want=0; Desc="User auto-elevate" }
    @{ Name="PromptOnSecureDesktop";       Want=0; Desc="Secure desktop off" }
    @{ Name="EnableInstallerDetection";    Want=0; Desc="Installer detection off" }
    @{ Name="ValidateAdminCodeSignatures"; Want=0; Desc="No code signing check" }
    @{ Name="FilterAdministratorToken";    Want=0; Desc="No admin token filter" }
)

$uacFixed = 0
foreach ($uac in $uacChecks) {
    $current = (Get-ItemProperty $uacPath -Name $uac.Name -ErrorAction SilentlyContinue)."$($uac.Name)"
    if ($current -ne $uac.Want) {
        Set-ItemProperty $uacPath -Name $uac.Name -Value $uac.Want -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  [FIXED] $($uac.Desc): $current -> $($uac.Want)" -ForegroundColor Green
        $uacFixed++
        $fixed++
    }
}
if ($uacFixed -eq 0) {
    Write-Host "  [OK] All UAC values correct" -ForegroundColor DarkGray
}
Log "Shield: UAC lockdown verified ($uacFixed fixed)"

# ================================================================
# Phase 5: Re-apply YAZX TCP/IP Tweaks (Nagle, MMCSS, etc.)
# ================================================================
# These registry values are set by Module 17 (Nagle) and Module 14.
# Oneclick doesn't directly reset these, but Windows Updates might.

Write-Host ""
Write-Host "  --- Phase 5: TCP/IP & MMCSS Verification ---" -ForegroundColor Yellow

$tcpFixed = 0

# MMCSS (Multimedia Class Scheduler)
$mmcssPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$mmcssChecks = @(
    @{ Path=$mmcssPath; Name="NetworkThrottlingIndex"; Want=4294967295; Type="DWord"; Desc="NetworkThrottling=Unlimited" }
    @{ Path=$mmcssPath; Name="SystemResponsiveness";   Want=0;          Type="DWord"; Desc="SystemResponsiveness=0" }
)
foreach ($chk in $mmcssChecks) {
    if (Test-Path $chk.Path) {
        $current = (Get-ItemProperty $chk.Path -Name $chk.Name -ErrorAction SilentlyContinue)."$($chk.Name)"
        if ($current -ne $chk.Want) {
            Set-ItemProperty $chk.Path -Name $chk.Name -Value $chk.Want -Type $chk.Type -Force -ErrorAction SilentlyContinue
            Write-Host "  [FIXED] $($chk.Desc)" -ForegroundColor Green
            $tcpFixed++
            $fixed++
        }
    }
}

# TCP/IP Parameters
$tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$tcpChecks = @(
    @{ Name="DefaultTTL";     Want=255;   Desc="DefaultTTL=255" }
    @{ Name="MaxUserPort";    Want=65534; Desc="MaxUserPort=65534" }
)
foreach ($chk in $tcpChecks) {
    if (Test-Path $tcpPath) {
        $current = (Get-ItemProperty $tcpPath -Name $chk.Name -ErrorAction SilentlyContinue)."$($chk.Name)"
        if ($current -ne $chk.Want) {
            Set-ItemProperty $tcpPath -Name $chk.Name -Value $chk.Want -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "  [FIXED] $($chk.Desc)" -ForegroundColor Green
            $tcpFixed++
            $fixed++
        }
    }
}

# Nagle (per-interface TcpAckFrequency and TCPNoDelay)
$ifacesPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
if (Test-Path $ifacesPath) {
    $interfaces = Get-ChildItem $ifacesPath -ErrorAction SilentlyContinue
    foreach ($iface in $interfaces) {
        $dhcpIP = (Get-ItemProperty $iface.PSPath -Name DhcpIPAddress -ErrorAction SilentlyContinue).DhcpIPAddress
        $staticIP = (Get-ItemProperty $iface.PSPath -Name IPAddress -ErrorAction SilentlyContinue).IPAddress
        if ($dhcpIP -and $dhcpIP -ne "0.0.0.0" -or ($staticIP -and $staticIP -ne "0.0.0.0")) {
            $ack = (Get-ItemProperty $iface.PSPath -Name TcpAckFrequency -ErrorAction SilentlyContinue).TcpAckFrequency
            $noDelay = (Get-ItemProperty $iface.PSPath -Name TCPNoDelay -ErrorAction SilentlyContinue).TCPNoDelay
            if ($ack -ne 1) {
                Set-ItemProperty $iface.PSPath -Name TcpAckFrequency -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $tcpFixed++; $fixed++
            }
            if ($noDelay -ne 1) {
                Set-ItemProperty $iface.PSPath -Name TCPNoDelay -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $tcpFixed++; $fixed++
            }
        }
    }
}

if ($tcpFixed -eq 0) {
    Write-Host "  [OK] All TCP/IP & MMCSS values correct" -ForegroundColor DarkGray
} else {
    Write-Host "  [FIXED] $tcpFixed TCP/IP & MMCSS values corrected" -ForegroundColor Green
}
Log "Shield: TCP/IP & MMCSS verified ($tcpFixed fixed)"

# ================================================================
# Phase 6: Install Startup Protection (Run Registry)
# ================================================================
# Since Task Scheduler may be killed by PD, we use Run registry
# as a backup enforcement mechanism that survives PD.

Write-Host ""
Write-Host "  --- Phase 6: Startup Protection ---" -ForegroundColor Yellow

$shieldScript = "$YazxDir\scripts\YAZX_Shield_Startup.ps1"
$scriptsDir = "$YazxDir\scripts"
if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null }

$startupCode = @'
# YAZX Shield Startup Script - runs at every login
# Re-enables critical services and re-applies YAZX tweaks
# that Oneclick Process Destroyer may have broken

# Re-enable Schedule (Task Scheduler)
$sched = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Schedule" -Name Start -EA SilentlyContinue).Start
if ($sched -eq 4) {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Schedule" -Name Start -Value 2 -Force -EA SilentlyContinue
    Start-Service Schedule -EA SilentlyContinue
}

# Re-enable gpsvc (Group Policy Client)
$gp = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\gpsvc" -Name Start -EA SilentlyContinue).Start
if ($gp -eq 4) {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\gpsvc" -Name Start -Value 2 -Force -EA SilentlyContinue
}

# Re-enable QWAVE (QoS engine)
$qw = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\QWAVE" -Name Start -EA SilentlyContinue).Start
if ($qw -eq 4) {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\QWAVE" -Name Start -Value 3 -Force -EA SilentlyContinue
}

# UAC lockdown enforcement
$uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-ItemProperty $uacPath -Name ConsentPromptBehaviorAdmin -Value 0 -Force -EA SilentlyContinue
Set-ItemProperty $uacPath -Name PromptOnSecureDesktop -Value 0 -Force -EA SilentlyContinue
Set-ItemProperty $uacPath -Name ConsentPromptBehaviorUser -Value 0 -Force -EA SilentlyContinue

# Re-create UAC enforce task if missing (Task Destroyer may have deleted it)
$task = Get-ScheduledTask -TaskName "YAZX_UAC_Enforce" -EA SilentlyContinue
if (-not $task) {
    $cmd = 'Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Value 0 -Force; Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name PromptOnSecureDesktop -Value 0 -Force; Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorUser -Value 0 -Force'
    $a = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$cmd`""
    $t1 = New-ScheduledTaskTrigger -AtLogOn
    $t2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6)
    $p = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
    $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName "YAZX_UAC_Enforce" -Action $a -Trigger $t1,$t2 -Principal $p -Settings $s -Force -EA SilentlyContinue | Out-Null
}
'@

Set-Content -Path $shieldScript -Value $startupCode -Force -Encoding UTF8
Write-Host "  [OK] Shield startup script: $shieldScript" -ForegroundColor Green

# Register in Run key
$runKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$runValue = "Powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$shieldScript`""
$currentRun = (Get-ItemProperty $runKey -Name "YAZX Shield" -ErrorAction SilentlyContinue)."YAZX Shield"
if ($currentRun -ne $runValue) {
    Set-ItemProperty -Path $runKey -Name "YAZX Shield" -Value $runValue -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Startup Run entry registered: YAZX Shield" -ForegroundColor Green
    Log "Shield: Startup protection registered in HKLM Run"
    $fixed++
} else {
    Write-Host "  [OK] Startup Run entry already set" -ForegroundColor DarkGray
}

# ================================================================
# Summary
# ================================================================
Write-Host ""
if ($fixed -gt 0) {
    Write-Host "  [SHIELD] $fixed issues detected and fixed." -ForegroundColor Green
} else {
    Write-Host "  [SHIELD] All YAZX tweaks verified - no conflicts found." -ForegroundColor Green
}
Write-Host ""
Log "Module 19 YAZXShield: $fixed fixes applied. Completed"
