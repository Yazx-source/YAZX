param($YazxDir, $BackupDir, $LogFile, [switch]$Auto)
# YAZX Module 08 - Disable Unnecessary Services
# Based on YAZX system configuration + Oneclick Process Destroyer

. "$PSScriptRoot\YAZX_Common.ps1"
function Log($msg) { YAZX-Log $LogFile $msg }

Write-Host "`n  === YAZX Module 08: Services ===" -ForegroundColor Cyan
Log "Module 08 Services: Started"

# Backup current services state first
$backupReg = "$YazxDir\logs\Services_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
reg export "HKLM\SYSTEM\CurrentControlSet\Services" $backupReg /y 2>$null | Out-Null
Write-Host "  [OK] Services backup: $backupReg" -ForegroundColor Green
Log "Services backup: Created"

# Services to disable (from Oneclick + YAZX config)
$disableServices = @(
    # Telemetry & Data Collection
    @{Name="DiagTrack"; Desc="Connected User Experiences and Telemetry"}
    @{Name="dmwappushservice"; Desc="WAP Push Message Routing"}
    @{Name="diagnosticshub.standardcollector.service"; Desc="Diagnostics Hub"}

    # Windows Update related (handled by Oneclick Update Disabler)
    @{Name="wuauserv"; Desc="Windows Update"}
    @{Name="UsoSvc"; Desc="Update Orchestrator"}
    @{Name="WaaSMedicSvc"; Desc="WaaS Medic"}

    # Unnecessary services
    @{Name="MapsBroker"; Desc="Downloaded Maps Manager"}
    @{Name="lfsvc"; Desc="Geolocation Service"}
    @{Name="SharedAccess"; Desc="Internet Connection Sharing"}
    @{Name="RemoteRegistry"; Desc="Remote Registry"}
    @{Name="RemoteAccess"; Desc="Routing and Remote Access"}
    @{Name="WMPNetworkSvc"; Desc="WMP Network Sharing"}
    @{Name="WSearch"; Desc="Windows Search"}
    @{Name="SysMain"; Desc="Superfetch/SysMain"}
    @{Name="TabletInputService"; Desc="Touch Keyboard"}
    @{Name="PhoneSvc"; Desc="Phone Service"}
    @{Name="RetailDemo"; Desc="Retail Demo"}
    @{Name="WerSvc"; Desc="Windows Error Reporting"}
    @{Name="wisvc"; Desc="Windows Insider"}
    @{Name="WbioSrvc"; Desc="Windows Biometric"}
    @{Name="icssvc"; Desc="Windows Mobile Hotspot"}
    @{Name="Fax"; Desc="Fax"}
    @{Name="SEMgrSvc"; Desc="Payments and NFC"}
    @{Name="PcaSvc"; Desc="Program Compatibility Assistant"}

    # From Oneclick Process Destroyer
    @{Name="NgcCtnrSvc"; Desc="Microsoft Passport Container"}
    @{Name="NgcSvc"; Desc="Microsoft Passport"}
    @{Name="WpnUserService"; Desc="Windows Push Notifications"}
    @{Name="TimeBrokerSvc"; Desc="Time Broker"}
    @{Name="SystemEventsBroker"; Desc="System Events Broker"}

    # NVIDIA containers (from QuakedK)
    @{Name="NVDisplay.ContainerLocalSystem"; Desc="NVIDIA Container 1"}
    @{Name="NvContainerLocalSystem"; Desc="NVIDIA Container 2"}
)

$disabled = 0
foreach ($svc in $disableServices) {
    $s = Get-Service $svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        sc.exe config $svc.Name start=disabled 2>$null | Out-Null
        Stop-Service $svc.Name -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Disabled: $($svc.Name) ($($svc.Desc))" -ForegroundColor Green
        $disabled++
    }
}

# --- Core Services (requires Oneclick confirmation) ---
$coreServices = @(
    @{Name="EventSystem"; Desc="COM+ Event System"}
    @{Name="gpsvc"; Desc="Group Policy Client"}
)
$runCore = $false
if ($Auto) {
    Write-Host "  [!] Skipping EventSystem/gpsvc in Auto mode (requires Oneclick confirmation)" -ForegroundColor Yellow
    Log "Services: EventSystem/gpsvc skipped (Auto mode, needs Oneclick confirmation)"
} else {
    Write-Host ""
    Write-Host "  [!] EventSystem and gpsvc are core Windows services." -ForegroundColor Yellow
    Write-Host "      Only disable these if Oneclick Process Destroyer was already run." -ForegroundColor Yellow
    $confirm = YAZX-Choose -Title "Disable EventSystem and gpsvc?" -Labels @("Yes - Oneclick was run", "No - Skip these") -Values @(1, 0)
    if ($confirm -eq 1) { $runCore = $true }
}
if ($runCore) {
    foreach ($svc in $coreServices) {
        $s = Get-Service $svc.Name -ErrorAction SilentlyContinue
        if ($s) {
            sc.exe config $svc.Name start=disabled 2>$null | Out-Null
            Stop-Service $svc.Name -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Disabled: $($svc.Name) ($($svc.Desc))" -ForegroundColor Green
            $disabled++
        }
    }
    Log "Services: EventSystem/gpsvc disabled (user confirmed Oneclick)"
}

# --- Windows Update Recovery Prevention ---
Write-Host "`n  --- Windows Update Recovery Prevention ---" -ForegroundColor Yellow

# Disable WU scheduled task triggers that re-enable updates
$wuTasks = @(
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start",
    "\Microsoft\Windows\WindowsUpdate\sih",
    "\Microsoft\Windows\WindowsUpdate\sihboot",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task",
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask",
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker",
    "\Microsoft\Windows\WaaSMedic\PerformRemediation"
)
foreach ($task in $wuTasks) {
    schtasks /change /tn $task /disable 2>$null | Out-Null
}
Write-Host "  [OK] Windows Update task triggers disabled" -ForegroundColor Green

# Prevent WaaS Medic from re-enabling services
$medicPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (-not (Test-Path $medicPath)) { New-Item -Path $medicPath -Force | Out-Null }
Set-ItemProperty -Path $medicPath -Name "DisableWUfBSafeguards" -Value 1 -Type DWord -Force
$medicAU = "$medicPath\AU"
if (-not (Test-Path $medicAU)) { New-Item -Path $medicAU -Force | Out-Null }
Set-ItemProperty -Path $medicAU -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
Write-Host "  [OK] WaaS Medic recovery prevention applied" -ForegroundColor Green

Log "Module 08 Services: $disabled services disabled + WU recovery prevention. Completed"
Write-Host "`n  [OK] $disabled services disabled + WU hardened.`n" -ForegroundColor Green
