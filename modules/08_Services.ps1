param($YazxDir, $BackupDir, $LogFile)
# YAZX Module 08 - Disable Unnecessary Services
# Based on YAZX system configuration + Oneclick Process Destroyer

function Log($msg) { "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $msg" | Out-File $LogFile -Append -Encoding UTF8 }

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

    # From Oneclick Process Destroyer (aggressive - run AFTER Oneclick prepares the system)
    # WARNING: EventSystem and gpsvc are core Windows services.
    # Only safe to disable after Oneclick has been run and system is configured.
    @{Name="EventSystem"; Desc="COM+ Event System (disable after Oneclick)"}
    @{Name="gpsvc"; Desc="Group Policy Client (disable after Oneclick)"}
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

Log "Module 08 Services: $disabled services disabled. Completed"
Write-Host "`n  [OK] $disabled services disabled.`n" -ForegroundColor Green
