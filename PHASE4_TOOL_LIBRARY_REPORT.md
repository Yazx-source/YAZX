# YAZX Phase 4 — Tool Library Report
# Date: 2026-11-20
# System: Intel i5-13400F / RTX 3060 12GB / 32GB DDR4

---

## What Was Done

1. **VSTPlugins copied** (268 files, 12.5 MB) from yazx_VSTPlugins to exports/VSTPlugins/
   - rnnoise_stereo.dll (8.4 MB) — noise suppression for HyperX mic
   - ReaPlugs suite (267 files) — reacomp, reagate, reaeq, reafir, etc.
   - Required for Equalizer APO mic.txt restore

2. **TTCH .pow file search completed** — no valid binary exists
   - active_plan.pow in backup = 0 bytes
   - TTCH_UltimatePerformance.pow in YAZX_GitHub = 0 bytes
   - Copied TTCH_UltimatePerformance_Full.txt (12.4 KB) — text reference
   - **Restore path**: Power_Control.reg (1637.5 KB) via `reg import`

3. **Tool library manifest created**: tools/YAZX_TOOL_LIBRARY.md
   - 17 tools documented with: name, version, files, source, SHA-256,
     dependencies, config files, collection status
   - 268 VST plugin files documented
   - 7 tool configs documented (Process Lasso, MSI AB, NVIDIA, Realtek, EQ APO, Mem Reduct, ParkControl)
   - 2 app configs documented (ExplorerPatcher, OpenShell)
   - Power plans documented (3 valid, 1 invalid)
   - 11 kernel settings documented with registry paths, values, and types
   - 5 filesystem settings documented

4. **Module 14 safety verified**:
   - YAZX_NewTweaks.reg contains ONLY SAFE tweaks (CsEnabled=0, GameMode, GameDVR)
   - YAZX_NewTweaks_Candidates.reg has candidates COMMENTED OUT (not importable)
   - 14_NewTweaks.ps1 is diagnostic-only (shows state, applies nothing)
   - "Run ALL" in YAZX_Setup.bat only imports SAFE tweaks
   - Memory Compression, IRQ Affinity, RSS Affinity are NOT auto-applied

5. **Integrity checks completed**:
   - Zero-byte files: 2 found
     - exports/TTCH_UltimatePerformance.pow — KNOWN INVALID, documented
     - exports/Steam/virtualgamepadinfo.txt — empty Steam file, harmless
   - HTML masquerading: None found
   - SHA-256 verification: 5 signed tools ALL MATCH recorded hashes
   - Duplicate files found:
     - prolasso_affinity.ini = exact copy of prolasso.ini
     - Performances_CPU.nip = exact copy of Performances.nip
   - No settings files lost or corrupted

6. **Manifest regenerated**: YAZX_MANIFEST.txt
   - Previous: 387 files, 820 MB
   - Current: 734 files, 1133 MB (1.11 GB)
   - 124 directories

---

## Integrity Check Results

### Zero-Byte Files (2)

| File | Reason | Action |
|------|--------|--------|
| exports/TTCH_UltimatePerformance.pow | Failed export (no admin) | Documented as INVALID. Use Power_Control.reg |
| exports/Steam/virtualgamepadinfo.txt | Empty Steam metadata | Harmless, leave as-is |

### SHA-256 Verification (5 signed tools)

| Tool | Status |
|------|--------|
| O&O ShutUp10 (OOSU10.exe) | MATCH |
| GPU-Z (GPU-Z.exe) | MATCH |
| DDU (DDU_v18.1.6.3.exe) | MATCH |
| QuickCPU (QuickCpuSetup.msi) | MATCH |
| IRQControl (irqcontrolsetup64.exe) | MATCH |

### Duplicate Files (2 pairs)

| File 1 | File 2 | Action |
|--------|--------|--------|
| prolasso.ini (17.9 KB) | prolasso_affinity.ini (17.9 KB) | Same content. Both kept for compatibility |
| Performances.nip (22.1 KB) | Performances_CPU.nip (22.1 KB) | Same content. Both kept — may serve different import paths |

### HTML Masquerading Check
No executable, ZIP, or MSI files contain HTML content. All downloads are genuine.

---

## Tool Status Summary

| # | Tool | Version | Status | Notes |
|---|------|---------|--------|-------|
| 1 | Sysinternals Suite | Latest | COMPLETE | 164 tools extracted |
| 2 | MouseTester | v1.5.3 | COMPLETE | |
| 3 | WinMTR | v1.00 | COMPLETE | Static build |
| 4 | CapFrameX | v1.9.2 | COMPLETE | + 2 deps (VC++, .NET 10) |
| 5 | O&O ShutUp10++ | v3.7 | COMPLETE | Signed |
| 6 | USBTreeView | Latest | COMPLETE | |
| 7 | ISLC | v1.0.3.2 | COMPLETE | |
| 8 | LatencyMon | Latest | COMPLETE | |
| 9 | QuickCPU | Latest | COMPLETE | Signed, MSI |
| 10 | GPU-Z | v2.72.0 | COMPLETE | Signed |
| 11 | ThrottleStop | v9.7.3 | COMPLETE | Limited on locked CPU |
| 12 | DDU | v18.1.6.3 | COMPLETE | Signed |
| 13 | IRQControl | v1.0.0.65 | COMPLETE | **BETA**, signed (Bitsum) |
| 14 | CrystalDiskInfo | 9.9.5 | **NOT DOWNLOADED** | crystalmark.info/en/download/ |
| 15 | CrystalDiskMark | 9.0.3 | **NOT DOWNLOADED** | crystalmark.info/en/download/ |
| 16 | HWiNFO | v8.60+ | **NOT DOWNLOADED** | hwinfo.com/download/ |
| 17 | SG TCP Optimizer | Latest | **NOT DOWNLOADED** | speedguide.net/downloads.php |

---

## Tweak Safety Classification (unchanged)

| Classification | Count | Auto-applied? |
|----------------|-------|---------------|
| SAFE | 6 | YES (via YAZX_NewTweaks.reg in Run ALL) |
| CANDIDATE | 8 | NO (commented out, manual only) |
| EXPERIMENTAL | 2 | NO (PowerShell only, manual only) |

Kernel settings are documented as DISCOVERED state, not recommendations.

---

## What Cannot Be Done Without Admin

| Item | Reason | Workaround |
|------|--------|-----------|
| Memory Compression state | Get-MMAgent requires elevation | Check post-format |
| Scheduled Tasks export | TaskCache requires elevation | Cross-ref from Services_All.csv |
| Autologgers/ETW export | Autologger tree requires elevation | Document known loggers |
| BCD full export | bcdedit requires elevation | Partial from registry |
| EnableLUA fix | Registry + Appinfo service both broken | Fix post-format or via recovery |

EnableLUA is NOT a blocker for Phase 4 completion.

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| tools/YAZX_TOOL_LIBRARY.md | Complete per-tool manifest |
| exports/VSTPlugins/ (268 files) | VST plugins for EQ APO |
| exports/PowerPlans/TTCH_UltimatePerformance_Full.txt | TTCH plan text reference |
| PHASE4_TOOL_LIBRARY_REPORT.md | This report |
| YAZX_MANIFEST.txt | Regenerated (734 files, 1.13 GB) |
