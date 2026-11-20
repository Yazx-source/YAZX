# YAZX Tool Verification Script
# Run after format to verify all tools are installed and accessible

Write-Host ""
Write-Host "  YAZX Tool Verification"
Write-Host "  ======================"
Write-Host ""

$results = @()

function Test-Tool {
    param([string]$Name, [string]$Path, [string]$Priority)
    $exists = Test-Path $Path
    $status = if ($exists) { "[OK]" } else { "[MISSING]" }
    $color = if ($exists) { "Green" } else { "Red" }
    Write-Host "  $status $Name" -ForegroundColor $color
    return [PSCustomObject]@{ Name=$Name; Status=$status; Priority=$Priority; Path=$Path }
}

Write-Host "  Critical Tools:"
$results += Test-Tool "Process Lasso" "${env:ProgramFiles}\Process Lasso\ProcessLasso.exe" "Critical"
$results += Test-Tool "NVIDIA Driver" "${env:ProgramFiles}\NVIDIA Corporation\NVSMI\nvidia-smi.exe" "Critical"
$results += Test-Tool "IRQControl" "${env:ProgramFiles}\Process Lasso\irqcontrol.exe" "Critical"
$results += Test-Tool "DDU" "E:\YAZX_GitHub\tools\DDU\Display Driver Uninstaller.exe" "Critical"

Write-Host ""
Write-Host "  High Priority Tools:"
$results += Test-Tool "MSI Afterburner" "${env:ProgramFiles(x86)}\MSI Afterburner\MSIAfterburner.exe" "High"
$results += Test-Tool "RTSS" "${env:ProgramFiles(x86)}\RivaTuner Statistics Server\RTSS.exe" "High"
$results += Test-Tool "NVIDIA Profile Inspector" "E:\YAZX_GitHub\tools\*\nvidiaProfileInspector.exe" "High"
$results += Test-Tool "HWiNFO" "${env:ProgramFiles}\HWiNFO64\HWiNFO64.exe" "High"
$results += Test-Tool "CapFrameX" "E:\YAZX_GitHub\tools\CapFrameX\CapFrameX.exe" "High"
$results += Test-Tool "SG TCP Optimizer" "E:\YAZX_GitHub\tools\SG_TCP_Optimizer\TCPOptimizer.exe" "High"
$results += Test-Tool "LatencyMon" "${env:ProgramFiles}\LatencyMon\LatMon.exe" "High"

Write-Host ""
Write-Host "  Medium Priority Tools:"
$results += Test-Tool "CrystalDiskInfo" "E:\YAZX_GitHub\tools\CrystalDiskInfo\DiskInfo*.exe" "Medium"
$results += Test-Tool "USBTreeView" "E:\YAZX_GitHub\tools\USBTreeView\USBTreeView.exe" "Medium"
$results += Test-Tool "O&O ShutUp10++" "E:\YAZX_GitHub\tools\OO_ShutUp10\OOSU10.exe" "Medium"
$results += Test-Tool "Mem Reduct" "${env:ProgramFiles}\Henry++\memreduct\memreduct.exe" "Medium"
$results += Test-Tool "Equalizer APO" "${env:ProgramFiles}\EqualizerAPO\Editor.exe" "Medium"

Write-Host ""
Write-Host "  Utility Tools:"
$results += Test-Tool "7-Zip" "${env:ProgramFiles}\7-Zip\7z.exe" "Utility"
$results += Test-Tool "LibreWolf" "${env:ProgramFiles}\LibreWolf\librewolf.exe" "Utility"

Write-Host ""
$ok = ($results | Where-Object { $_.Status -eq "[OK]" }).Count
$missing = ($results | Where-Object { $_.Status -eq "[MISSING]" }).Count
Write-Host "  Summary: $ok installed, $missing missing of $($results.Count) total" -ForegroundColor $(if ($missing -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($missing -gt 0) {
    Write-Host "  Missing tools need manual installation."
    Write-Host "  See: E:\YAZX_GitHub\tools\YAZX_DownloadGuide.md"
    Write-Host ""
}
