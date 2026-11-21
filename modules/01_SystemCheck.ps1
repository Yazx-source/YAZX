param($YazxDir, $BackupDir, $LogFile, [switch]$Auto)
# YAZX Module 01 - System Check
# Verifies system compatibility before applying tweaks

. "$PSScriptRoot\YAZX_Common.ps1"
function Log($msg) { YAZX-Log $LogFile $msg }

Write-Host "`n  === YAZX Module 01: System Check ===" -ForegroundColor Cyan
Log "Module 01 SystemCheck: Started"

# OS Version
$os = Get-CimInstance Win32_OperatingSystem
$build = [System.Environment]::OSVersion.Version.Build
Write-Host "  OS: $($os.Caption)" -ForegroundColor White
Write-Host "  Build: $build (UBR: $(Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'UBR' -ErrorAction SilentlyContinue))" -ForegroundColor White
Log "OS: $($os.Caption) Build $build"

if ($build -lt 26100) {
    Write-Host "  [!] WARNING: Expected Build 26100+ (Win11 24H2 IoT LTSC)" -ForegroundColor Yellow
    Log "WARNING: Build $build is lower than expected 26100"
}

# CPU
$cpu = (Get-CimInstance Win32_Processor).Name
Write-Host "  CPU: $cpu" -ForegroundColor White
Log "CPU: $cpu"

# GPU
$gpu = (Get-CimInstance Win32_VideoController).Name
Write-Host "  GPU: $gpu" -ForegroundColor White
Log "GPU: $gpu"

if ($gpu -notmatch "RTX 3060") {
    Write-Host "  [!] WARNING: Expected RTX 3060. Some GPU tweaks may not apply." -ForegroundColor Yellow
}

# RAM
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "  RAM: ${ram} GB" -ForegroundColor White
Log "RAM: ${ram} GB"

# Drives
Write-Host "  Drives:" -ForegroundColor White
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $free = [math]::Round($_.FreeSpace / 1GB, 1)
    $total = [math]::Round($_.Size / 1GB, 1)
    Write-Host "    $($_.DeviceID) $free/$total GB free" -ForegroundColor Gray
}

# Check backup folder
if (Test-Path $BackupDir) {
    $backupFolders = (Get-ChildItem $BackupDir -Directory).Count
    Write-Host "  Backup: $backupFolders folders at $BackupDir" -ForegroundColor Green
    Log "Backup folder: $backupFolders folders found"
} else {
    Write-Host "  Backup: NOT FOUND at $BackupDir" -ForegroundColor Red
    Log "Backup folder: NOT FOUND"
}

# Check EnableLUA
$lua = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" -ErrorAction SilentlyContinue
Write-Host "  EnableLUA: $lua $(if($lua -eq 0){'(Disabled - correct)'}else{'(Enabled - needs fix!)'})" -ForegroundColor $(if($lua -eq 0){'Green'}else{'Red'})

# Check Appinfo service
$appinfo = Get-Service AppInfo -ErrorAction SilentlyContinue
if ($appinfo) {
    Write-Host "  Appinfo: $($appinfo.Status)" -ForegroundColor White
} else {
    Write-Host "  Appinfo: DELETED (expected after Oneclick)" -ForegroundColor Yellow
}

# --- DPC Latency Check ---
Write-Host "`n  --- DPC Latency ---" -ForegroundColor Yellow
try {
    $dpcTimer = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "GlobalTimerResolutionRequests" -ErrorAction SilentlyContinue).GlobalTimerResolutionRequests
    Write-Host "  GlobalTimerResolutionRequests: $(if($dpcTimer -eq 1){'Enabled (apps honored)'}else{'Not set (default)'})" -ForegroundColor White

    $nvDpc = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" -Name "RmGpsPsEnablePerCpuCoreDpc" -ErrorAction SilentlyContinue).RmGpsPsEnablePerCpuCoreDpc
    Write-Host "  NVIDIA PerCpuCoreDpc: $(if($nvDpc -eq 1){'Enabled'}else{'Not set'})" -ForegroundColor White

    $msiCount = 0
    @("PCI", "HDAUDIO", "USB") | ForEach-Object {
        $enumPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$_"
        if (Test-Path $enumPath) {
            Get-ChildItem $enumPath -Recurse -Depth 4 -ErrorAction SilentlyContinue |
                Where-Object { $_.PSChildName -eq "Device Parameters" } |
                Get-ItemProperty -Name "MSISupported" -ErrorAction SilentlyContinue |
                Where-Object { $_.MSISupported -eq 1 } | ForEach-Object { $msiCount++ }
        }
    }
    Write-Host "  MSI-enabled devices: $msiCount" -ForegroundColor White
    Log "DPC: TimerRes=$dpcTimer, NvDpc=$nvDpc, MSI=$msiCount"
} catch {
    Write-Host "  [!] Could not read DPC info" -ForegroundColor Yellow
}

Write-Host "`n  [OK] System check complete." -ForegroundColor Green
Log "Module 01 SystemCheck: Completed"
