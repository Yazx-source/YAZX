param($YazxDir, $BackupDir, $LogFile)
# YAZX Module 10 - MSI Mode for Devices
# Enables Message Signaled Interrupts on 7 devices

function Log($msg) { "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $msg" | Out-File $LogFile -Append -Encoding UTF8 }

Write-Host "`n  === YAZX Module 10: MSI Mode ===" -ForegroundColor Cyan
Log "Module 10 MSIMode: Started"

# Find device paths for MSI mode
$deviceClasses = @(
    @{Class="{4d36e968-e325-11ce-bfc1-08002be10318}"; Name="GPU (Display)"}
    @{Class="{4d36e972-e325-11ce-bfc1-08002be10318}"; Name="Network Adapter"}
    @{Class="{4d36e97b-e325-11ce-bfc1-08002be10318}"; Name="SCSI/Storage (NVMe)"}
    @{Class="{4d36e96c-e325-11ce-bfc1-08002be10318}"; Name="Audio"}
    @{Class="{4d36e96a-e325-11ce-bfc1-08002be10318}"; Name="IDE/AHCI"}
    @{Class="{36fc9e60-c465-11cf-8056-444553540000}"; Name="USB"}
)

$enabled = 0
foreach ($dev in $deviceClasses) {
    $basePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$($dev.Class)"
    if (Test-Path $basePath) {
        $subKeys = Get-ChildItem $basePath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^\d{4}$" }
        foreach ($sk in $subKeys) {
            $msiPath = "$($sk.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            try {
                if (-not (Test-Path $msiPath)) {
                    New-Item -Path $msiPath -Force | Out-Null
                }
                Set-ItemProperty -Path $msiPath -Name "MSISupported" -Value 1 -Type DWord -Force
                $devDesc = (Get-ItemProperty $sk.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue).DriverDesc
                if ($devDesc) {
                    Write-Host "  [OK] MSI Mode: $devDesc ($($dev.Name))" -ForegroundColor Green
                    $enabled++
                }
            } catch {
                Write-Host "  [!] Failed to set MSI for $($dev.Name): $_" -ForegroundColor Yellow
            }
        }
    }
}

# Set MSI mode limit for NVIDIA GPU (find correct subkey by DriverDesc)
$gpuBasePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
$gpuSubKeys = Get-ChildItem $gpuBasePath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^\d{4}$" }
foreach ($sk in $gpuSubKeys) {
    $desc = (Get-ItemProperty $sk.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue).DriverDesc
    if ($desc -match "NVIDIA|RTX|GeForce") {
        $gpuMsiPath = "$($sk.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        if (Test-Path $gpuMsiPath) {
            Set-ItemProperty -Path $gpuMsiPath -Name "MessageNumberLimit" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] GPU MSI MessageNumberLimit = 2 ($desc)" -ForegroundColor Green
        }
        break
    }
}

Log "Module 10 MSIMode: $enabled devices configured. Completed"
Write-Host "`n  [OK] MSI Mode enabled on $enabled devices. Reboot required.`n" -ForegroundColor Green
