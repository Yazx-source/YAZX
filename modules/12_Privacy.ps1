param($YazxDir, $BackupDir, $LogFile)
# YAZX Module 12 - Privacy
# Telemetry, hosts file cleanup, tracking disable

function Log($msg) { "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $msg" | Out-File $LogFile -Append -Encoding UTF8 }

Write-Host "`n  === YAZX Module 12: Privacy ===" -ForegroundColor Cyan
Log "Module 12 Privacy: Started"

# --- Disable Telemetry Services ---
Write-Host "  --- Telemetry Services ---" -ForegroundColor Yellow
$telServices = @("DiagTrack", "dmwappushservice", "diagnosticshub.standardcollector.service")
foreach ($svc in $telServices) {
    $s = Get-Service $svc -ErrorAction SilentlyContinue
    if ($s) {
        sc.exe config $svc start=disabled 2>$null | Out-Null
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Disabled: $svc" -ForegroundColor Green
    }
}

# --- Telemetry Registry ---
Write-Host "  --- Telemetry Registry ---" -ForegroundColor Yellow
$telReg = @(
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Value=0}
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="MaxTelemetryAllowed"; Value=0}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name="AllowTelemetry"; Value=0}
    @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"; Name="TailoredExperiencesWithDiagnosticDataEnabled"; Value=0}
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name="DisabledByGroupPolicy"; Value=1}
    @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"; Value=0}
    @{Path="HKCU:\SOFTWARE\Microsoft\Input\TIPC"; Name="Enabled"; Value=0}
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name="AITEnable"; Value=0}
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name="DisableUAR"; Value=1}
)

foreach ($r in $telReg) {
    if (-not (Test-Path $r.Path)) { New-Item -Path $r.Path -Force | Out-Null }
    Set-ItemProperty -Path $r.Path -Name $r.Name -Value $r.Value -Type DWord -Force
}
Write-Host "  [OK] Telemetry registry entries applied" -ForegroundColor Green

# --- Scheduled Tasks (disable telemetry tasks) ---
Write-Host "  --- Telemetry Tasks ---" -ForegroundColor Yellow
$telTasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Feedback\Siuf\DmClient"
)

foreach ($task in $telTasks) {
    schtasks /change /tn $task /disable 2>$null | Out-Null
}
Write-Host "  [OK] Telemetry tasks disabled" -ForegroundColor Green

# --- Disable Activity History ---
Write-Host "  --- Activity History ---" -ForegroundColor Yellow
$actPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $actPath)) { New-Item -Path $actPath -Force | Out-Null }
Set-ItemProperty -Path $actPath -Name "EnableActivityFeed" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $actPath -Name "PublishUserActivities" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $actPath -Name "UploadUserActivities" -Value 0 -Type DWord -Force
Write-Host "  [OK] Activity History disabled" -ForegroundColor Green

# --- Disable Location Tracking ---
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Location tracking disabled" -ForegroundColor Green

# --- TCP Auto-Tuning (Gaming Mode by TTCH) ---
Write-Host "  --- Network Gaming Mode ---" -ForegroundColor Yellow
netsh int tcp set global autotuninglevel=disabled 2>$null
Write-Host "  [OK] TCP auto-tuning disabled (TTCH Gaming Mode)" -ForegroundColor Green

Log "Module 12 Privacy: Completed"
Write-Host "`n  [OK] Privacy module complete.`n" -ForegroundColor Green
