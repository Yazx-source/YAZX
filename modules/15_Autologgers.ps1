param($YazxDir, $BackupDir, $LogFile)
# YAZX Module 15 - ETW Autologger Destroyer
# Disables telemetry/diagnostic ETW autologger sessions

function Log($msg) { "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $msg" | Out-File $LogFile -Append -Encoding UTF8 }

Write-Host "`n  === YAZX Module 15: Autologgers ===" -ForegroundColor Cyan
Log "Module 15 Autologgers: Started"

$autologgers = @(
    "AutoLogger-Diagtrack-Listener",
    "SQMLogger",
    "WiFiDriverIHVSession",
    "WiFiSession",
    "Cellcore",
    "AppModel",
    "CloudExperienceHostOobe",
    "DiagLog",
    "NtfsLog",
    "TileStore",
    "UBPM",
    "WdiContextLog",
    "ReadyBoot",
    "RadioMgr",
    "LwtNetLog",
    "Circular Kernel Context Logger"
)

$basePath = "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger"
$disabled = 0

foreach ($logger in $autologgers) {
    $loggerPath = "$basePath\$logger"
    if (Test-Path $loggerPath) {
        try {
            Set-ItemProperty -Path $loggerPath -Name "Start" -Value 0 -Type DWord -Force
            Write-Host "  [OK] Disabled: $logger" -ForegroundColor Green
            $disabled++
        } catch {
            Write-Host "  [!] Failed: $logger (access denied)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [--] Not found: $logger" -ForegroundColor Gray
    }
}

# Disable MpWppTracing autologgers (Defender-related, variable names)
$mpLoggers = Get-ChildItem $basePath -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match "MpWppTracing" }
foreach ($mp in $mpLoggers) {
    try {
        Set-ItemProperty -Path $mp.PSPath -Name "Start" -Value 0 -Type DWord -Force
        Write-Host "  [OK] Disabled: $($mp.PSChildName)" -ForegroundColor Green
        $disabled++
    } catch {}
}

Log "Module 15 Autologgers: $disabled autologgers disabled. Completed"
Write-Host "`n  [OK] $disabled autologgers disabled.`n" -ForegroundColor Green
