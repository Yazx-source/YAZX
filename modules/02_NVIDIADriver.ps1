param($YazxDir, $BackupDir, $LogFile)
# YAZX Module 02 - NVIDIA Driver Installation
# Uses NVCleanInstall for minimal gaming driver

function Log($msg) { "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $msg" | Out-File $LogFile -Append -Encoding UTF8 }

Write-Host "`n  === YAZX Module 02: NVIDIA Driver ===" -ForegroundColor Cyan
Log "Module 02 NVIDIADriver: Started"

# Check current driver
$currentDriver = $null
try {
    $currentDriver = (nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>$null).Trim()
} catch {}

if ($currentDriver) {
    Write-Host "  Current driver: $currentDriver" -ForegroundColor White
    Log "Current NVIDIA driver: $currentDriver"
} else {
    Write-Host "  No NVIDIA driver detected." -ForegroundColor Yellow
}

# NVCleanInstall
$nvclean = "$YazxDir\tools\NVCleanInstall"
if (-not (Test-Path "$nvclean\NVCleanstall.exe")) {
    Write-Host "  Downloading NVCleanInstall..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $nvclean -Force | Out-Null
    $nvUrl = "https://www.techpowerup.com/download/techpowerup-nvcleanstall/"
    Write-Host "  [!] Download NVCleanInstall manually from:" -ForegroundColor Red
    Write-Host "      https://www.techpowerup.com/nvcleaninstall/" -ForegroundColor White
    Write-Host "      Extract to: $nvclean" -ForegroundColor White
    Log "NVCleanInstall: Not found, manual download needed"
} else {
    Write-Host "  [OK] NVCleanInstall found" -ForegroundColor Green
}

# NVIDIA Profile Inspector
Write-Host "`n  --- NVIDIA Profile Inspector ---" -ForegroundColor Yellow
$npiSrc = "$BackupDir\yazx_NVIDIA_ProfileInspector\nvidiaProfileInspector.exe"
$npiDst = "$env:ProgramFiles\NVIDIA Profile Inspector"

if (Test-Path $npiSrc) {
    New-Item -ItemType Directory -Path $npiDst -Force | Out-Null
    Copy-Item "$BackupDir\yazx_NVIDIA_ProfileInspector\nvidiaProfileInspector.exe" "$npiDst\" -Force
    Write-Host "  [OK] NVIDIA Profile Inspector installed" -ForegroundColor Green
    Log "NVIDIA Profile Inspector: Installed"

    # Import YAZX profile (Performances.nip = user's custom profile)
    $profileSrc = "$YazxDir\configs\NVIDIA_Inspector\Performances.nip"
    if (Test-Path $profileSrc) {
        Copy-Item $profileSrc "$npiDst\Performances.nip" -Force
        Write-Host "  [OK] YAZX profile (Performances.nip) copied" -ForegroundColor Green
        Write-Host "  [!] Open NVIDIA Profile Inspector and import Performances.nip" -ForegroundColor Yellow
        Log "NVIDIA Profile: Performances.nip copied"
    }
} else {
    Write-Host "  [!] NVIDIA Profile Inspector not in backup" -ForegroundColor Red
    Write-Host "      Download from: https://github.com/Orbmu2k/nvidiaProfileInspector" -ForegroundColor White
}

# NVIDIA Container services are disabled by Module 08 (Services).

# NVCleanInstall recommended settings
Write-Host "`n  --- NVCleanInstall Settings (for manual use) ---" -ForegroundColor Yellow
Write-Host "  When using NVCleanInstall:" -ForegroundColor White
Write-Host "    KEEP:" -ForegroundColor Green
Write-Host "      - Display Driver" -ForegroundColor Gray
Write-Host "      - PhysX System Software" -ForegroundColor Gray
Write-Host "      - HD Audio via HDMI (if using HDMI audio)" -ForegroundColor Gray
Write-Host "    REMOVE:" -ForegroundColor Red
Write-Host "      - NVIDIA App / GeForce Experience" -ForegroundColor Gray
Write-Host "      - NvContainer / Telemetry" -ForegroundColor Gray
Write-Host "      - NV NodeJS / Backend" -ForegroundColor Gray
Write-Host "      - Shield Wireless Controller" -ForegroundColor Gray
Write-Host "    TWEAKS:" -ForegroundColor Yellow
Write-Host "      [x] Disable Installer Telemetry" -ForegroundColor Gray
Write-Host "      [x] Disable Multiplane Overlay (MPO)" -ForegroundColor Gray
Write-Host "      [x] Disable NVIDIA HD Audio device sleep timer" -ForegroundColor Gray
Write-Host "      [x] Perform a Clean Installation" -ForegroundColor Gray

# --- NVIDIA Registry Tweaks (from Oneclick comparison) ---
Write-Host "`n  --- NVIDIA Registry Tweaks ---" -ForegroundColor Yellow

# Per-CPU core DPC handling
$nvDrvPath = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" -Name "ImagePath" -ErrorAction SilentlyContinue).ImagePath
if ($nvDrvPath) {
    $nvParamsPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters"
    if (-not (Test-Path $nvParamsPath)) { New-Item -Path $nvParamsPath -Force | Out-Null }
    Set-ItemProperty -Path $nvParamsPath -Name "RmGpsPsEnablePerCpuCoreDpc" -Value 1 -Type DWord -Force
    Write-Host "  [OK] RmGpsPsEnablePerCpuCoreDpc = 1" -ForegroundColor Green

    # FTS (Frame Transport Settings)
    $ftsPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS"
    if (-not (Test-Path $ftsPath)) { New-Item -Path $ftsPath -Force | Out-Null }
    Set-ItemProperty -Path $ftsPath -Name "EnableRID73779" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $ftsPath -Name "EnableRID74361" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $ftsPath -Name "EnableRID73different" -Value 0 -Type DWord -Force
    Write-Host "  [OK] FTS flags set" -ForegroundColor Green

    # Disable NVIDIA telemetry
    $nvTelPaths = @(
        "HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client",
        "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS"
    )
    foreach ($tp in $nvTelPaths) {
        if (-not (Test-Path $tp)) { New-Item -Path $tp -Force | Out-Null }
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" -Name "OptInOrOutPreference" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS" -Name "EnableRID66610" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS" -Name "EnableRID64640" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS" -Name "EnableRID44231" -Value 0 -Type DWord -Force
    Write-Host "  [OK] NVIDIA telemetry disabled" -ForegroundColor Green

    Log "NVIDIA registry tweaks: Applied (DPC, FTS, telemetry)"
} else {
    Write-Host "  [!] NVIDIA driver not found, skipping registry tweaks" -ForegroundColor Yellow
}

# Disable NVIDIA scheduled tasks
Get-ScheduledTask | Where-Object { $_.TaskName -match "Nvidia|NvTm" } | ForEach-Object {
    Disable-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  [OK] Disabled task: $($_.TaskName)" -ForegroundColor Green
}

Log "Module 02 NVIDIADriver: Completed"
Write-Host "`n  [OK] NVIDIA module complete." -ForegroundColor Green
