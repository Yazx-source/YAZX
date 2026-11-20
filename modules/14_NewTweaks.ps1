param(
    [string]$YazxDir,
    [string]$BackupDir,
    [string]$LogFile
)

# YAZX Module 14: New Tweaks — CANDIDATE Operations
# STATUS: This module does NOT auto-apply anything.
# Each tweak requires explicit -Apply flag or manual confirmation.
# Run without flags to see diagnostic report only.

Write-Host ""
Write-Host "  Module 14: New Tweaks — Candidate Review"
Write-Host "  =========================================="
Write-Host "  STATUS: Diagnostic mode (no changes applied)"
Write-Host "  To apply a specific tweak, run with its flag."
Write-Host ""

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# --- Diagnostic: Show current state of each candidate ---

Write-Host "  === Current System State ==="
Write-Host ""

# 1. GlobalTimerResolutionRequests
Write-Host "  [1] GlobalTimerResolutionRequests"
try {
    $val = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "GlobalTimerResolutionRequests" -ErrorAction Stop).GlobalTimerResolutionRequests
    Write-Host "      Current: $val"
} catch {
    Write-Host "      Current: NOT SET (default = applications may be ignored)"
}
Write-Host "      Candidate value: 1 (honor app timer requests)"
Write-Host "      Classification: CANDIDATE"
Write-Host "      Risk: Low (may increase idle power ~1W)"
Write-Host "      Restore: Set to 0 or delete value"
Write-Host ""

# 2. LargeSystemCache
Write-Host "  [2] LargeSystemCache"
try {
    $val = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -ErrorAction Stop).LargeSystemCache
    Write-Host "      Current: $val"
} catch {
    Write-Host "      Current: NOT SET (default on workstation = 0)"
}
Write-Host "      Candidate value: 0 (prioritize app memory)"
Write-Host "      Classification: CANDIDATE (may already be default)"
Write-Host "      Risk: Minimal"
Write-Host "      Restore: Set to 0 (default)"
Write-Host ""

# 3. Memory Compression
Write-Host "  [3] Memory Compression"
try {
    $mc = (Get-MMAgent -ErrorAction Stop).MemoryCompression
    Write-Host "      Current: $mc"
} catch {
    Write-Host "      Current: UNKNOWN (requires admin elevation)"
}
Write-Host "      Candidate: Disabled"
Write-Host "      Classification: EXPERIMENTAL"
Write-Host "      Risk: MEDIUM — may cause paging to disk under memory pressure"
Write-Host "      Restore: Enable-MMAgent -MemoryCompression"
Write-Host ""

# 4. Heterogeneous Thread Policy
Write-Host "  [4] Heterogeneous Thread Policy (P-core preference)"
try {
    $result = powercfg /qh SCHEME_CURRENT SUB_PROCESSOR 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2>&1
    $current = ($result | Select-String "Current.*:").ToString() -replace '.*:\s*', ''
    Write-Host "      Current: $current"
} catch {
    Write-Host "      Current: UNKNOWN"
}
Write-Host "      Candidate value: 4 (Prefer performant processors)"
Write-Host "      Classification: CANDIDATE"
Write-Host "      Risk: Low (well-documented Windows setting for hybrid CPUs)"
Write-Host "      Restore: powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SCHEDPOLICY 0"
Write-Host ""

# 5. PCIe ASPM
Write-Host "  [5] PCIe ASPM (Link State Power Management)"
try {
    $result = powercfg /qh SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 2>&1
    $current = ($result | Select-String "Current.*:").ToString() -replace '.*:\s*', ''
    Write-Host "      Current: $current"
} catch {
    Write-Host "      Current: UNKNOWN"
}
Write-Host "      Candidate value: 0 (Off — no link state power saving)"
Write-Host "      Classification: CANDIDATE"
Write-Host "      Risk: Low (increases PCIe power, prevents micro-latency)"
Write-Host "      Restore: powercfg /setacvalueindex ... 2 (Moderate)"
Write-Host ""

Write-Host "  === Instructions ==="
Write-Host "  To apply individual tweaks, import from:"
Write-Host "    registry\YAZX_NewTweaks_Candidates.reg (Timer, LargeSystemCache)"
Write-Host "  Or run PowerShell commands manually:"
Write-Host "    Disable-MMAgent -MemoryCompression  (Memory Compression)"
Write-Host "    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SCHEDPOLICY 4"
Write-Host "    powercfg /setacvalueindex SCHEME_CURRENT 501a4d13... ee12f906... 0"
Write-Host ""
Write-Host "  Benchmark each tweak individually before keeping it."
Write-Host ""

if ($LogFile) {
    Add-Content $LogFile "[$timestamp] Module 14: Diagnostic report shown. No changes applied."
}
