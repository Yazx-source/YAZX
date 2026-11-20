# YAZX Realtek RSS Affinity — Diagnostic and Candidate Script
# STATUS: CANDIDATE — does NOT auto-apply. Reports current state only
#         unless -Apply is explicitly passed.
# Run as Administrator AFTER format

param(
    [switch]$Apply,
    [switch]$Restore
)

Write-Host ""
Write-Host "  YAZX Realtek RSS Affinity — Diagnostic"
Write-Host "  ========================================"
Write-Host "  STATUS: Candidate script (not auto-applied)"
Write-Host ""

# Step 1: Detect adapter
$adapter = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like "*Realtek*2.5*" -or
    $_.InterfaceDescription -like "*RTL8125*"
}

if (-not $adapter) {
    Write-Host "  [!] Realtek 2.5GbE adapter not found!" -ForegroundColor Red
    Write-Host "  Verify adapter is installed and driver is loaded."
    exit 1
}

Write-Host "  Adapter: $($adapter.InterfaceDescription)"
Write-Host "  Name:    $($adapter.Name)"
Write-Host "  Status:  $($adapter.Status)"
Write-Host ""

# Step 2: Report current RSS configuration
Write-Host "  Current RSS Configuration:"
$rss = Get-NetAdapterRss -Name $adapter.Name -ErrorAction SilentlyContinue
if ($rss) {
    Write-Host "    Enabled:              $($rss.Enabled)"
    Write-Host "    NumberOfReceiveQueues: $($rss.NumberOfReceiveQueues)"
    Write-Host "    BaseProcessorNumber:   $($rss.BaseProcessorNumber)"
    Write-Host "    MaxProcessorNumber:    $($rss.MaxProcessorNumber)"
    Write-Host "    MaxProcessors:         $($rss.MaxProcessors)"
    Write-Host "    Profile:               $($rss.Profile)"
    Write-Host ""

    # Save current values for restore
    $currentBase = $rss.BaseProcessorNumber
    $currentMax = $rss.MaxProcessorNumber
    $currentQueues = $rss.NumberOfReceiveQueues
} else {
    Write-Host "    [!] RSS not supported or not available on this adapter"
    exit 1
}

# Step 3: Detect CPU topology
Write-Host "  CPU Topology:"
$cpu = Get-CimInstance Win32_Processor
Write-Host "    Model:   $($cpu.Name)"
Write-Host "    Cores:   $($cpu.NumberOfCores)"
Write-Host "    Threads: $($cpu.NumberOfLogicalProcessors)"

# Check if hybrid (P+E cores)
$isHybrid = $cpu.Name -match "13[4-9]\d\d|14[4-9]\d\d|Core Ultra"
Write-Host "    Hybrid:  $isHybrid"

if ($isHybrid) {
    Write-Host ""
    Write-Host "  [INFO] Hybrid CPU detected."
    Write-Host "  P-core affinity MAY be beneficial but is NOT proven for this"
    Write-Host "  specific adapter+driver+CPU combination."
    Write-Host "  Benchmark with and without to determine actual benefit."
}

Write-Host ""

# Step 4: Handle -Restore
if ($Restore) {
    Write-Host "  Restoring RSS to default (auto)..."
    Set-NetAdapterRss -Name $adapter.Name -BaseProcessorNumber 0 -MaxProcessorNumber 15 -ErrorAction SilentlyContinue
    Write-Host "  [OK] RSS restored to default processor range (0-15)"
    exit 0
}

# Step 5: Handle -Apply (only with explicit flag)
if ($Apply) {
    Write-Host "  [WARNING] About to change RSS affinity."
    Write-Host "  Current: Base=$currentBase, Max=$currentMax, Queues=$currentQueues"
    Write-Host "  Proposed: Base=2, Max=8, Queues=4 (P-cores 1-4, threads 2-8)"
    Write-Host ""
    Write-Host "  This is a CANDIDATE setting that may or may not improve performance."
    Write-Host "  Benchmark before and after to verify."
    Write-Host ""

    $confirm = Read-Host "  Type YES to apply, anything else to cancel"
    if ($confirm -eq "YES") {
        Set-NetAdapterRss -Name $adapter.Name `
            -NumberOfReceiveQueues 4 `
            -BaseProcessorNumber 2 `
            -MaxProcessorNumber 8 `
            -ErrorAction SilentlyContinue
        Write-Host "  [OK] RSS settings applied. Verify with:"
        Write-Host "       Get-NetAdapterRss -Name '$($adapter.Name)'"
        Write-Host ""
        Write-Host "  To restore: Run this script with -Restore"
    } else {
        Write-Host "  Cancelled."
    }
} else {
    Write-Host "  This script is diagnostic only. To apply changes:"
    Write-Host "    .\YAZX_Apply_RSS_Affinity.ps1 -Apply"
    Write-Host "  To restore defaults:"
    Write-Host "    .\YAZX_Apply_RSS_Affinity.ps1 -Restore"
}
