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

# === Summary ===

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Device Manager Summary" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Devices disabled : $disabled" -ForegroundColor $(if ($disabled -gt 0) { "Green" } else { "Gray" })
if ($nicKey) {
    Write-Host "    NIC settings     : $applied applied" -ForegroundColor Green
}
Write-Host "    [!] Reboot required for changes to take effect" -ForegroundColor Yellow
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""

Log "Module 17 DeviceManager: $disabled devices disabled. Completed"
