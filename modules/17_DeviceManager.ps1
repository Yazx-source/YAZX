param(
    [string]$YazxDir,
    [string]$BackupDir,
    [string]$LogFile,
    [switch]$Auto
)

# YAZX Module 17 - Device Manager Restoration
# Disables performance-harming devices and applies NIC optimization
# Based on pre-format Device Manager snapshot

. "$PSScriptRoot\YAZX_Common.ps1"
function Log($msg) { YAZX-Log $LogFile $msg }

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    YAZX Module 17: Device Manager" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Log "Module 17 DeviceManager: Started"

# === Phase 1: Disable devices that were disabled pre-format ===

Write-Host "  --- Disabling Performance-Harming Devices ---" -ForegroundColor Yellow

$disableDevices = @(
    @{ Name="Printer Port (LPT1)";           Id="ACPI\PNP0400\0" }
    @{ Name="Communications Port (COM1)";    Id="ACPI\PNP0501\0" }
    @{ Name="Resource Hub proxy device";     Id="ACPI\MSFT8000\1" }
    @{ Name="ACPI Processor Aggregator";     Id="ACPI\ACPI000C\2&daba3ff&0" }
    @{ Name="WMI for ACPI (GSADEV0)";       Id="ACPI\PNP0C14\GSADEV0" }
    @{ Name="WMI for ACPI (DSarDev)";       Id="ACPI\PNP0C14\DSarDev" }
    @{ Name="WMI for ACPI (TestDev)";       Id="ACPI\PNP0C14\TestDev" }
    @{ Name="ACPI Thermal Zone (TZ00)";     Id="ACPI\ThermalZone\TZ00" }
    @{ Name="ACPI Thermal Zone (TZ10)";     Id="ACPI\ThermalZone\TZ10" }
    @{ Name="High precision event timer";   Id="ACPI\PNP0103\0" }
    @{ Name="ACPI Wake Alarm";              Id="ACPI\ACPI000E\2&daba3ff&0" }
    @{ Name="NVIDIA HD Audio";              Id="HDAUDIO\FUNC_01&VEN_10DE&DEV_009F&SUBSYS_19DA4630&REV_1001\5&183128f1&0&0001" }
    @{ Name="Microsoft GS Wavetable Synth"; Id="SWD\MMDEVAPI\MicrosoftGSWavetableSynth" }
    @{ Name="Intel Management Engine";      Id="PCI\VEN_8086&DEV_7A68&SUBSYS_1C3A1458&REV_11\3&11583659&0&B0" }
    @{ Name="Programmable interrupt ctrl";  Id="ACPI\PNP0000\4&7a92c67&0" }
)

$disabled = 0
$skipped = 0
foreach ($dev in $disableDevices) {
    $status = (pnputil /enum-devices /instanceid $dev.Id 2>$null) -join "`n"
    if ($status -match "Status:\s+Started|Status:\s+OK") {
        $result = pnputil /disable-device $dev.Id 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Disabled: $($dev.Name)" -ForegroundColor Green
            $disabled++
        } else {
            Write-Host "  [!] Failed to disable: $($dev.Name)" -ForegroundColor Yellow
            $skipped++
        }
    } elseif ($status -match "Status:\s+Disabled") {
        Write-Host "  [OK] Already disabled: $($dev.Name)" -ForegroundColor DarkGreen
        $disabled++
    } else {
        Write-Host "  [--] Not found: $($dev.Name)" -ForegroundColor Gray
        $skipped++
    }
}
Log "DeviceManager: $disabled devices disabled, $skipped skipped"

# === Phase 2: Realtek Gaming 2.5GbE Network Adapter Optimization ===

Write-Host ""
Write-Host "  --- Network Adapter Optimization (Realtek 2.5GbE) ---" -ForegroundColor Yellow

$nicBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
$nicKey = $null
$nicSubs = Get-ChildItem $nicBase -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' }
foreach ($sk in $nicSubs) {
    $desc = (Get-ItemProperty $sk.PSPath -ErrorAction SilentlyContinue).DriverDesc
    if ($desc -match "Realtek Gaming 2.5GbE") {
        $nicKey = $sk.PSPath
        break
    }
}

if ($nicKey) {
    $nicSettings = @{
        "*SpeedDuplex"              = @{ Value=2500;  Type="String"; Desc="Speed: 2.5 Gbps Full" }
        "*FlowControl"              = @{ Value=0;     Type="String"; Desc="Flow Control: Disabled" }
        "*InterruptModeration"      = @{ Value=0;     Type="String"; Desc="Interrupt Moderation: Disabled" }
        "*IPChecksumOffloadIPv4"    = @{ Value=0;     Type="String"; Desc="IPv4 Checksum Offload: Disabled" }
        "*TCPChecksumOffloadIPv4"   = @{ Value=0;     Type="String"; Desc="TCP Checksum Offload v4: Disabled" }
        "*UDPChecksumOffloadIPv4"   = @{ Value=0;     Type="String"; Desc="UDP Checksum Offload v4: Disabled" }
        "*LsoV2IPv4"               = @{ Value=0;     Type="String"; Desc="Large Send Offload v2 IPv4: Disabled" }
        "*LsoV2IPv6"               = @{ Value=0;     Type="String"; Desc="Large Send Offload v2 IPv6: Disabled" }
        "*PriorityVlanTag"          = @{ Value=0;     Type="String"; Desc="Priority and VLAN: Disabled" }
        "*WakeOnPattern"            = @{ Value=0;     Type="String"; Desc="Wake on Pattern: Disabled" }
        "*WakeOnMagicPacket"        = @{ Value=0;     Type="String"; Desc="Wake on Magic Packet: Disabled" }
        "*PMARPOffload"             = @{ Value=0;     Type="String"; Desc="ARP Offload: Disabled" }
        "*PMNSOffload"              = @{ Value=0;     Type="String"; Desc="NS Offload: Disabled" }
        "*ModernStandbyWoLMagicPacket" = @{ Value=0;  Type="String"; Desc="Modern Standby WoL: Disabled" }
        "*EEE"                      = @{ Value=0;     Type="String"; Desc="Energy Efficient Ethernet: Disabled" }
        "AdvancedEEE"               = @{ Value=0;     Type="String"; Desc="Advanced EEE: Disabled" }
        "GigaLite"                  = @{ Value=0;     Type="String"; Desc="GigaLite: Disabled" }
        "EnableGreenEthernet"       = @{ Value=0;     Type="String"; Desc="Green Ethernet: Disabled" }
        "PowerSavingMode"           = @{ Value=0;     Type="String"; Desc="Power Saving Mode: Disabled" }
        "S5WakeOnLan"               = @{ Value=0;     Type="String"; Desc="Shutdown Wake on LAN: Disabled" }
        "S0MgcPkt"                  = @{ Value=0;     Type="String"; Desc="S0 Magic Packet: Disabled" }
        "*ReceiveBuffers"           = @{ Value=2048;  Type="String"; Desc="Receive Buffers: 2048" }
        "*TransmitBuffers"          = @{ Value=1024;  Type="String"; Desc="Transmit Buffers: 1024" }
        "*JumboPacket"              = @{ Value=1514;  Type="String"; Desc="Jumbo Packet: 1514 (Standard)" }
        "*RSS"                      = @{ Value=1;     Type="String"; Desc="RSS: Enabled" }
        "*NumRssQueues"             = @{ Value=4;     Type="String"; Desc="RSS Queues: 4" }
        "PnPCapabilities"           = @{ Value=280;   Type="DWord"; Desc="PnP: Disable power management" }
    }

    $applied = 0
    foreach ($key in $nicSettings.Keys) {
        $s = $nicSettings[$key]
        try {
            if ($s.Type -eq "DWord") {
                Set-ItemProperty -Path $nicKey -Name $key -Value $s.Value -Type DWord -Force -ErrorAction Stop
            } else {
                Set-ItemProperty -Path $nicKey -Name $key -Value "$($s.Value)" -Force -ErrorAction Stop
            }
            Write-Host "  [OK] $($s.Desc)" -ForegroundColor Green
            $applied++
        } catch {
            Write-Host "  [!] Failed: $($s.Desc)" -ForegroundColor Yellow
        }
    }
    Log "NIC: $applied of $($nicSettings.Count) settings applied to Realtek 2.5GbE"
} else {
    Write-Host "  [!] Realtek Gaming 2.5GbE not found - skipping NIC optimization" -ForegroundColor Yellow
    Log "NIC: Realtek Gaming 2.5GbE not found"
}

# === Phase 3: NVIDIA GPU Performance Registry ===

Write-Host ""
Write-Host "  --- NVIDIA GPU Performance Tweaks ---" -ForegroundColor Yellow

$gpuBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
$gpuKey = $null
$gpuSubs = Get-ChildItem $gpuBase -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' }
foreach ($sk in $gpuSubs) {
    $desc = (Get-ItemProperty $sk.PSPath -ErrorAction SilentlyContinue).DriverDesc
    if ($desc -match "NVIDIA|RTX|GeForce") {
        $gpuKey = $sk.PSPath
        Write-Host "  Found: $desc" -ForegroundColor Gray
        break
    }
}

if (-not $nicKey) { $applied = 0 }
$gpuApplied = 0
if ($gpuKey) {
    $gpuTweaks = @{
        "DisableDynamicPstate"  = @{ Value=1;    Type="DWord"; Desc="Disable dynamic P-state switching" }
        "PerfLevelSrc"          = @{ Value=8738;  Type="DWord"; Desc="Force max performance (0x2222)" }
        "RMHdcpKeyglobZero"     = @{ Value=1;    Type="DWord"; Desc="Disable HDCP overhead" }
        "RmProfilingAdminOnly"  = @{ Value=1;    Type="DWord"; Desc="Admin-only GPU profiling" }
    }
    foreach ($key in $gpuTweaks.Keys) {
        $t = $gpuTweaks[$key]
        try {
            Set-ItemProperty -Path $gpuKey -Name $key -Value $t.Value -Type $t.Type -Force -ErrorAction Stop
            Write-Host "  [OK] $($t.Desc)" -ForegroundColor Green
            $gpuApplied++
        } catch {
            Write-Host "  [!] Failed: $($t.Desc)" -ForegroundColor Yellow
        }
    }
    Log "GPU: $gpuApplied NVIDIA performance tweaks applied"
} else {
    Write-Host "  [!] No NVIDIA GPU found - skipping" -ForegroundColor Yellow
}

# === Phase 4: Nagle Algorithm Disable (per NIC interface) ===

Write-Host ""
Write-Host "  --- Nagle Algorithm Disable (TCP Optimization) ---" -ForegroundColor Yellow

$nagleApplied = 0
$ifBase = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem $ifBase -ErrorAction SilentlyContinue | ForEach-Object {
    $dhcp = (Get-ItemProperty $_.PSPath -Name "DhcpIPAddress" -ErrorAction SilentlyContinue).DhcpIPAddress
    $static = (Get-ItemProperty $_.PSPath -Name "IPAddress" -ErrorAction SilentlyContinue).IPAddress
    $ip = if ($dhcp -and $dhcp -ne "0.0.0.0") { $dhcp } elseif ($static) { ($static | Where-Object { $_ -and $_ -ne "0.0.0.0" }) | Select-Object -First 1 } else { $null }
    if ($ip) {
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Nagle disabled on interface $ip ($($_.PSChildName))" -ForegroundColor Green
        $nagleApplied++
    }
}
if ($nagleApplied -eq 0) {
    Write-Host "  [!] No active NIC interfaces found" -ForegroundColor Yellow
} else {
    Log "NIC: Nagle algorithm disabled on $nagleApplied interface(s)"
}

# === Phase 5: NVIDIA Control Panel Settings Restoration ===

Write-Host ""
Write-Host "  --- NVIDIA Control Panel Settings ---" -ForegroundColor Yellow

$nvRestore = 0
$nvDrsSrc = "$BackupDir\yazx_NVIDIA_Settings"

# 5a: Restore DRS database (all NVCP 3D settings)
$drsTarget = "$env:ProgramData\NVIDIA Corporation\Drs"
if ((Test-Path "$nvDrsSrc\nvdrsdb0.bin") -and (Test-Path $drsTarget)) {
    $nvsvc = Get-Service "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue
    $wasRunning = $nvsvc -and $nvsvc.Status -eq 'Running'
    if ($wasRunning) { Stop-Service "NVDisplay.ContainerLocalSystem" -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }
    Copy-Item "$nvDrsSrc\nvdrsdb0.bin" "$drsTarget\nvdrsdb0.bin" -Force -ErrorAction SilentlyContinue
    Copy-Item "$nvDrsSrc\nvdrsdb1.bin" "$drsTarget\nvdrsdb1.bin" -Force -ErrorAction SilentlyContinue
    Copy-Item "$nvDrsSrc\nvdrssel.bin" "$drsTarget\nvdrssel.bin" -Force -ErrorAction SilentlyContinue
    if ($wasRunning) { Start-Service "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue }
    Write-Host "  [OK] NVCP 3D settings restored (DRS database)" -ForegroundColor Green
    Log "NVCP: DRS database restored to $drsTarget"
    $nvRestore++
} elseif (-not (Test-Path $drsTarget)) {
    Write-Host "  [!] NVIDIA driver not installed yet - install driver first" -ForegroundColor Yellow
    Log "NVCP: Skipped DRS restore (driver not installed)"
} else {
    Write-Host "  [!] DRS backup not found in $nvDrsSrc" -ForegroundColor Yellow
}

# 5b: Import NVIDIA registry settings
foreach ($regFile in @("NVIDIA_HKCU.reg", "NVIDIA_HKLM.reg")) {
    $regPath = "$nvDrsSrc\$regFile"
    if (Test-Path $regPath) {
        $header = Get-Content $regPath -TotalCount 1 -ErrorAction SilentlyContinue
        if ($header -match "^Windows Registry Editor") {
            regedit /s $regPath
            Write-Host "  [OK] Imported: $regFile" -ForegroundColor Green
            $nvRestore++
        } else {
            Write-Host "  [!] Invalid reg header: $regFile - skipped" -ForegroundColor Yellow
        }
    }
}

# 5c: NPI profiles notification
$npiConfigs = "$YazxDir\configs\NVIDIA_Inspector"
$nipFiles = Get-ChildItem "$npiConfigs\*.nip" -ErrorAction SilentlyContinue
if ($nipFiles) {
    Write-Host "  [OK] NPI profiles available ($($nipFiles.Count) profiles in configs\)" -ForegroundColor Green
    Write-Host "       Load via NVIDIA Profile Inspector: File > Import" -ForegroundColor Gray
    $nvRestore++
} else {
    $nipBackup = Get-ChildItem "$BackupDir\yazx_NVIDIA_ProfileInspector\*.nip" -ErrorAction SilentlyContinue
    if ($nipBackup) {
        Write-Host "  [OK] NPI profiles in backup ($($nipBackup.Count) profiles)" -ForegroundColor Green
        Write-Host "       Load via NVIDIA Profile Inspector: File > Import" -ForegroundColor Gray
        $nvRestore++
    }
}
Log "NVCP: $nvRestore items restored"

# === Phase 6: Policy-based QoS (Per-App Network Priority) ===

Write-Host ""
Write-Host "  --- QoS Network Priority (Gaming Apps) ---" -ForegroundColor Yellow

$qosApplied = 0

$qosPolicies = @(
    @{ Name="YAZX - Rocket League";  App="RocketLeague.exe";       DSCP=46 }
)

foreach ($qos in $qosPolicies) {
    try {
        $existing = Get-NetQosPolicy -Name $qos.Name -PolicyStore localhost -ErrorAction SilentlyContinue
        if ($existing) { Remove-NetQosPolicy -Name $qos.Name -PolicyStore localhost -Confirm:$false -ErrorAction SilentlyContinue }
        New-NetQosPolicy -Name $qos.Name -AppPathNameMatchCondition $qos.App -DSCPAction $qos.DSCP -PolicyStore localhost -ErrorAction Stop | Out-Null
        $dscpLabel = if ($qos.DSCP -eq 46) { "EF (Highest)" } elseif ($qos.DSCP -eq 34) { "AF41 (High)" } else { "$($qos.DSCP)" }
        Write-Host "  [OK] $($qos.App) = DSCP $($qos.DSCP) ($dscpLabel)" -ForegroundColor Green
        $qosApplied++
    } catch {
        Write-Host "  [!] Failed: $($qos.Name) - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

$qosCustom = "$YazxDir\configs\qos_apps.txt"
if (Test-Path $qosCustom) {
    Get-Content $qosCustom -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -and -not $_.StartsWith("#") } | ForEach-Object {
        $parts = $_ -split "\s*[,|]\s*"
        if ($parts.Count -ge 2) {
            $appName = $parts[0].Trim()
            $appExe = $parts[1].Trim()
            $dscp = if ($parts.Count -ge 3) { [int]$parts[2].Trim() } else { 46 }
            $policyName = "YAZX - $appName"
            try {
                $existing = Get-NetQosPolicy -Name $policyName -PolicyStore localhost -ErrorAction SilentlyContinue
                if ($existing) { Remove-NetQosPolicy -Name $policyName -PolicyStore localhost -Confirm:$false -ErrorAction SilentlyContinue }
                New-NetQosPolicy -Name $policyName -AppPathNameMatchCondition $appExe -DSCPAction $dscp -PolicyStore localhost -ErrorAction Stop | Out-Null
                Write-Host "  [OK] $appExe = DSCP $dscp (custom)" -ForegroundColor Green
                $qosApplied++
            } catch {
                Write-Host "  [!] Failed: $policyName" -ForegroundColor Yellow
            }
        }
    }
}

if ($qosApplied -gt 0) {
    Log "QoS: $qosApplied policies applied (DSCP priority)"
} else {
    Write-Host "  [!] No QoS policies applied" -ForegroundColor Yellow
    Log "QoS: No policies applied"
}

# === Summary ===

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Device Manager Summary" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Devices disabled : $disabled" -ForegroundColor $(if ($disabled -gt 0) { "Green" } else { "Gray" })
if ($nicKey) {
    Write-Host "    NIC settings     : $applied applied" -ForegroundColor Green
}
Write-Host "    GPU tweaks       : $gpuApplied applied" -ForegroundColor $(if ($gpuApplied -gt 0) { "Green" } else { "Gray" })
Write-Host "    Nagle disabled   : $nagleApplied interface(s)" -ForegroundColor $(if ($nagleApplied -gt 0) { "Green" } else { "Gray" })
Write-Host "    NVCP restored    : $nvRestore item(s)" -ForegroundColor $(if ($nvRestore -gt 0) { "Green" } else { "Gray" })
Write-Host "    QoS policies     : $qosApplied app(s)" -ForegroundColor $(if ($qosApplied -gt 0) { "Green" } else { "Gray" })
Write-Host "    [!] Reboot required for changes to take effect" -ForegroundColor Yellow
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""

Log "Module 17 DeviceManager: $disabled devices, $applied NIC, $gpuApplied GPU, $nagleApplied Nagle, $nvRestore NVCP, $qosApplied QoS. Completed"
