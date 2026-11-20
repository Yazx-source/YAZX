# YAZX Tool Library — Automated Download Script
# Downloads all missing tools from official sources
# Run as Administrator for best results
# DO NOT run any tools — this only downloads them

param(
    [string]$ToolsDir = "$PSScriptRoot",
    [switch]$SkipExisting
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

Write-Host @"

  YAZX Tool Downloader
  ====================
  Downloads missing tools to: $ToolsDir

"@

function Download-Tool {
    param(
        [string]$Name,
        [string]$Url,
        [string]$OutDir,
        [string]$FileName
    )
    $outPath = Join-Path $OutDir $FileName
    if ($SkipExisting -and (Test-Path $outPath)) {
        Write-Host "  [SKIP] $Name — already exists" -ForegroundColor Yellow
        return $true
    }
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    Write-Host "  [DOWN] $Name..." -NoNewline
    try {
        Invoke-WebRequest -Uri $Url -OutFile $outPath -UseBasicParsing -TimeoutSec 120
        $size = (Get-Item $outPath).Length
        Write-Host " OK ($([Math]::Round($size/1MB, 2)) MB)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

$results = @()

# === CRITICAL PRIORITY ===
Write-Host "`n[CRITICAL] Essential tools" -ForegroundColor Red

# DDU — Display Driver Uninstaller
$r = Download-Tool -Name "DDU (Display Driver Uninstaller)" `
    -Url "https://www.wagnardsoft.com/DDU/download/DDU%20v18.0.9.3.exe" `
    -OutDir "$ToolsDir\DDU" -FileName "DDU_Setup.exe"
$results += [PSCustomObject]@{Tool="DDU";Status=if($r){"OK"}else{"FAILED"};Priority="Critical"}

# === HIGH PRIORITY ===
Write-Host "`n[HIGH] Important diagnostic and monitoring tools" -ForegroundColor Yellow

# GPU-Z
$r = Download-Tool -Name "GPU-Z" `
    -Url "https://www.techpowerup.com/download/techpowerup-gpu-z/" `
    -OutDir "$ToolsDir\GPU-Z" -FileName "GPU-Z_README.txt"
# GPU-Z requires manual download from TechPowerUp (no direct link)
if (-not $r) {
    Set-Content "$ToolsDir\GPU-Z\DOWNLOAD_MANUALLY.txt" @"
GPU-Z — Download manually from:
https://www.techpowerup.com/gpuz/
Choose: Standard Version (portable)
Save as: GPU-Z.2.62.0.exe (or latest)
"@
    Write-Host "  [INFO] GPU-Z requires manual download — instructions saved" -ForegroundColor Cyan
}

# CrystalDiskInfo
$r = Download-Tool -Name "CrystalDiskInfo Portable" `
    -Url "https://sourceforge.net/projects/crystaldiskinfo/files/latest/download" `
    -OutDir "$ToolsDir\CrystalDiskInfo" -FileName "CrystalDiskInfo_Setup.exe"
$results += [PSCustomObject]@{Tool="CrystalDiskInfo";Status=if($r){"OK"}else{"MANUAL"};Priority="High"}

# CrystalDiskMark
$r = Download-Tool -Name "CrystalDiskMark Portable" `
    -Url "https://sourceforge.net/projects/crystaldiskmark/files/latest/download" `
    -OutDir "$ToolsDir\CrystalDiskMark" -FileName "CrystalDiskMark_Setup.exe"
$results += [PSCustomObject]@{Tool="CrystalDiskMark";Status=if($r){"OK"}else{"MANUAL"};Priority="Medium"}

# === MEDIUM PRIORITY ===
Write-Host "`n[MEDIUM] Useful optimization and analysis tools" -ForegroundColor Cyan

# Sysinternals Suite — direct from Microsoft
$r = Download-Tool -Name "Sysinternals Suite" `
    -Url "https://download.sysinternals.com/files/SysinternalsSuite.zip" `
    -OutDir "$ToolsDir\Sysinternals" -FileName "SysinternalsSuite.zip"
$results += [PSCustomObject]@{Tool="Sysinternals Suite";Status=if($r){"OK"}else{"FAILED"};Priority="Medium"}

# HWiNFO64
$r = Download-Tool -Name "HWiNFO64 Portable" `
    -Url "https://www.sac.sk/download/utildiag/hwi_820.zip" `
    -OutDir "$ToolsDir\HWiNFO" -FileName "HWiNFO_Portable.zip"
$results += [PSCustomObject]@{Tool="HWiNFO64";Status=if($r){"OK"}else{"MANUAL"};Priority="Medium"}

# === TOOLS REQUIRING MANUAL DOWNLOAD ===
Write-Host "`n[MANUAL] Tools that need manual download (no direct link)" -ForegroundColor Magenta

$manualTools = @(
    @{Name="IRQControl"; Url="https://bitsum.com/parkcontrol/"; Note="Check if bundled with Process Lasso Pro, or download standalone from Bitsum"}
    @{Name="CapFrameX"; Url="https://github.com/CXWorld/CapFrameX/releases"; Note="Download latest .zip from GitHub Releases"}
    @{Name="LatencyMon"; Url="https://www.resplendence.com/latencymon"; Note="Download installer from resplendence.com"}
    @{Name="SG TCP Optimizer"; Url="https://www.speedguide.net/downloads.php"; Note="Download TCPOptimizer.exe (portable)"}
    @{Name="USBTreeView"; Url="https://www.uwe-sieber.de/usbtreeview_e.html"; Note="Download latest .zip (portable)"}
    @{Name="O&O ShutUp10++"; Url="https://www.oo-software.com/en/shutup10"; Note="Download OOSU10.exe (portable, single file)"}
    @{Name="ThrottleStop"; Url="https://www.techpowerup.com/download/techpowerup-throttlestop/"; Note="Download .zip (portable)"}
    @{Name="Quick CPU"; Url="https://coderbag.com/product/quickcpu"; Note="Download installer from CoderBag"}
    @{Name="ISLC"; Url="https://www.wagnardsoft.com/ISLCw"; Note="Download .exe (portable) from Wagnard"}
    @{Name="WinMTR"; Url="https://sourceforge.net/projects/winmtr/"; Note="Download portable .zip"}
    @{Name="GPU-Z"; Url="https://www.techpowerup.com/gpuz/"; Note="Download standard version (portable)"}
    @{Name="MouseTester"; Url="https://github.com/dobragab/MouseTester/releases"; Note="Download from GitHub Releases"}
)

foreach ($tool in $manualTools) {
    $instrFile = "$ToolsDir\$($tool.Name)\DOWNLOAD_INFO.txt"
    if (-not (Test-Path (Split-Path $instrFile))) {
        New-Item -ItemType Directory -Path (Split-Path $instrFile) -Force | Out-Null
    }
    Set-Content $instrFile @"
$($tool.Name)
==============
Official URL: $($tool.Url)
Note: $($tool.Note)
Download to this folder.
"@
    Write-Host "  [INFO] $($tool.Name) — instructions saved"
    $results += [PSCustomObject]@{Tool=$tool.Name;Status="MANUAL";Priority="Varies"}
}

# === SUMMARY ===
Write-Host "`n========================================" -ForegroundColor White
Write-Host "  Download Summary" -ForegroundColor White
Write-Host "========================================" -ForegroundColor White
$results | Format-Table -AutoSize

$autoCount = ($results | Where-Object { $_.Status -eq "OK" }).Count
$manualCount = ($results | Where-Object { $_.Status -eq "MANUAL" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "FAILED" }).Count

Write-Host "Auto-downloaded: $autoCount | Manual needed: $manualCount | Failed: $failCount"
Write-Host "`nManual download tools have instructions in their folders."
Write-Host "After downloading, run YAZX_VerifyTools.ps1 to verify all tools are present."
