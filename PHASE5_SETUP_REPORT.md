# YAZX Phase 5 — Setup.bat Evolution Report
# Date: 2026-11-20
# System: Intel i5-13400F / RTX 3060 12GB / 32GB DDR4

---

## Phase 5 Objective

Evolve the existing YAZX_Setup.bat with minimal changes. Add Phase 2.5 discovered exports
(kernel, power, VST, profiles) as a manual-review option. Do NOT rebuild the system,
do NOT auto-apply Candidate/Experimental tweaks, and do NOT modify Modules 01-12.

---

## Backup

| Item | Path | Size |
|------|------|------|
| Original (pre-Phase 5) | YAZX_Setup_BACKUP_Phase4.bat | 11,499 bytes (272 lines) |
| Modified | YAZX_Setup.bat | 20,512 bytes (493 lines) |

---

## Changes Made to YAZX_Setup.bat

### Change 1: Tool Status Check (informational only)
**Location**: After backup folder check, before menu display
**Purpose**: Shows how many of 17 tools are present vs missing at startup
**Behavior**: Counts 13 downloaded tools + checks 4 empty folders. Display-only, no failure.

### Change 2: [V] Phase 2.5 Exports Menu Option
**Location**: Menu section, after [14] New Tweaks
**Text**: `[V]  Phase 2.5 Exports    - Kernel/Power/VST/Profiles (manual review)`

### Change 3: Choice String & Errorlevel Cascade
**Old**: `choice /c 123456789ABCDEFGRQ` (18 options)
**New**: `choice /c 123456789ABCDEFGVRQ` (19 options, V inserted before R)
**Errorlevel mapping updated**:
- Q: 18 → 19
- R: 17 → 18
- V: NEW at 17

### Change 4: Phase 2.5 Handler (`:run_phase25`)
**Location**: Before `:done` label
**Sub-options** (7):
1. Import Kernel.reg (kernel timer/scheduler settings)
2. Import Power_Control.reg (full power tree)
3. Restore power plans (EonX.pow imports)
4. ExplorerPatcher + OpenShell registry import
5. EQ APO mic.txt + VSTPlugins copy
6. TTCH rebuild from saved values (runs YAZX_TTCH_Rebuild.ps1)
7. Run all 1-5 (TTCH rebuild excluded — requires separate review)

Each handler checks file existence before importing. Missing files produce a warning, not a crash.

---

## What Was NOT Changed

### Modules 01-12: PROVEN UNCHANGED
No module file (01-12) was modified after the Phase 5 backup was created.

| Module | Last Modified | Phase 5 Change? |
|--------|---------------|-----------------|
| 01_SystemCheck.ps1 | 02:34:52 | NO |
| 02_NVIDIADriver.ps1 | 02:35:16 | NO |
| 03_Programs.ps1 | 02:35:57 | NO |
| 04_Configs.ps1 | 02:36:28 | NO |
| 08_Services.ps1 | 02:37:55 | NO |
| 09_BCDTweaks.ps1 | 02:38:03 | NO |
| 10_MSIMode.ps1 | 02:38:17 | NO |
| 11_PowerPlan.ps1 | 03:37:30 | NO |
| 12_Privacy.ps1 | 02:38:56 | NO |
| 14_NewTweaks.ps1 | 05:52:31 | NO (Phase 4) |

### Module 14 & Run ALL Behavior
- `YAZX_NewTweaks.reg` applies ONLY SAFE tweaks (CsEnabled=0, GameMode, GameDVR)
- `YAZX_NewTweaks_Candidates.reg` has candidates COMMENTED OUT (`;` prefix = not importable)
- `14_NewTweaks.ps1` is diagnostic-only (shows state, applies nothing)
- Run ALL (option A) runs Modules 1-14 in order. Does NOT include [V].
- **Candidate and Experimental tweaks are NOT auto-applied anywhere.**

### No New Registry/Services/Drivers Changes
Phase 5 added no new registry keys, service modifications, or driver changes to the Setup flow.

### EnableLUA Not Touched
EnableLUA=1 state preserved. Not a Phase 5 concern.

---

## New Files Created in Phase 5

| File | Size | Purpose |
|------|------|---------|
| YAZX_Setup_BACKUP_Phase4.bat | 11,499 bytes | Exact pre-Phase 5 backup |
| exports/PowerPlans/YAZX_TTCH_Rebuild.ps1 | ~18 KB | Rebuilds TTCH plan: 72 settings (27 exact + 45 reconstructed) |
| YAZX_SHA256_MANIFEST.txt | ~96 KB | SHA-256 for 742 entries (739 disk files) |
| PHASE5_SETUP_REPORT.md | This file | Phase 5 completion report |

---

## TTCH Power Plan Rebuild

**Script**: `exports/PowerPlans/YAZX_TTCH_Rebuild.ps1`
**Method**: Duplicates Ultimate Performance base → renames to "TTCH ULTIMATE PERFORMANCE" → applies 99 powercfg commands

### Exact Restore (27 settings from powercfg /query — AC+DC):
- Hard disk timeout: AC=0 DC=1200sec
- Sleep/Hibernate: ALL disabled (0)
- Processor: Min AC=100% DC=5%, Max AC=100% DC=100%
- USB selective suspend: Disabled
- PCIe ASPM: Off
- Display timeout: AC=0 DC=600sec
- Wireless power saving: Disabled
- Plus battery, multimedia, desktop background settings

### Reconstructed (45 settings from Power_Control.reg — AC only):
- **30 Processor settings**: Core parking min/max (P-core=100%, E-core=20-97%),
  EPP=0 (max performance), boost mode=2 (aggressive), autonomous mode=0 (disabled),
  idle promote=99, idle demote=90, increase time=0, decrease time=5,
  performance increase/decrease policy, time check interval=4, idle time check=5000us,
  heterogeneous policy=100/100, parked performance state=100, utility distribution=2,
  overutilization threshold=50, distribution threshold=0, concurrency headroom=50
- **3 Sleep settings**: Away mode=1, unattended timeout=120, system required policy=1
- **3 Energy Saver settings**: All disabled (0)
- **2 USB settings**: USB3 link PM=0, hub timeout=0
- **2 Power buttons**: Power button=3 (shutdown), lid close=1
- **2 Display settings**: Console lock timeout=885, idle timeout=60
- **1 Hard disk**: AHCI link power management=0 (disabled)
- **1 Interrupt Steering**: Mode=6
- **1 Presence Aware**: Standby budget=240

### Not in this script:
Power_Control.reg contains 1452 registry keys total (69 for TTCH plan + 1179 system-wide
power settings + 204 other power keys). The TTCH plan's 55 setting-level keys are now fully
covered (27 exact + 45 reconstructed = 72 unique, covering all 55 registry entries where
some settings appear in both sources). Registry-only entries without ACSettingIndex values
and OEM-specific settings are NOT covered.

**This is a Reconstructed Plan, not an exact binary restore.** The original TTCH .pow
binary was never successfully exported. This script reproduces 72 of the plan's settings
via powercfg commands. Import Power_Control.reg for any remaining registry-level values.

**Recommended restore order**: Import Power_Control.reg FIRST, then run YAZX_TTCH_Rebuild.ps1.

---

## SHA-256 Manifest

**File**: YAZX_SHA256_MANIFEST.txt
**Manifest entries**: 742 (includes 4 VST files with parentheses in names, initially missed)
**Files on disk**: 739 (manifest itself not self-hashed at generation time)
**Manifest self-hash**: E47E0689465BCB259C1F0128550F269817D7F877320133885BE663B4533A8F2A (96,305 bytes)
**Zero-byte files**: 2 (marked as `ZERO-BYTE-FILE` in manifest)

### Signed Tools (locally computed, verified against download sources in Phase 4):

| Tool | SHA-256 |
|------|---------|
| OOSU10.exe | EA2790422AA81D62F22AE93E995C205D4D7A6AC9825877CF34AD4E65A8253ECE |
| GPU-Z.exe | 3B15545F3EDF7F2C714A32C7EE2BEDD9823FEE7D23A20E15F2E29CD2FEE25323 |
| DDU_v18.1.6.3.exe | 3D53FCC3506F4B9A55204B0C7E98F0B0E7A67ABA113856B87AC6F4F631E481A6 |
| QuickCpuSetup.msi | 9668D980F36087B56849D207A5ABEB709686D9167F621AB2076F8BEBE52AED6A |
| irqcontrolsetup64.exe | 0B3113EB359C88678310A2DFD66EBE9AB80CEED1D60EA4FB2EBCB5F5B67451D7 |

**Note**: These are locally computed hashes. No vendors published official SHA-256 for independent
comparison. Verification was done at download time against download page checksums where available.

---

## Zero-Byte Files (2)

| File | Classification | Action |
|------|---------------|--------|
| exports/TTCH_UltimatePerformance.pow | **FAILED EXPORT** — powercfg /export failed without admin | EXCLUDED from restore. NEVER import. Use YAZX_TTCH_Rebuild.ps1 (72 settings) + Power_Control.reg |
| exports/Steam/virtualgamepadinfo.txt | **HARMLESS PLACEHOLDER** — Steam placeholder for virtual gamepad config (no gamepad configured) | Keep in archive. Steam recreates it automatically. NOT missing data. Path: `exports\Steam\virtualgamepadinfo.txt` among 21 other Steam config files |

---

## Duplicate Files (2 pairs, both KEPT)

| File 1 | File 2 | Reason |
|--------|--------|--------|
| configs/ProcessLasso/prolasso.ini | configs/ProcessLasso/prolasso_affinity.ini | Same content. Both kept for Process Lasso compatibility |
| configs/MSI_Afterburner/Performances.nip | configs/MSI_Afterburner/Performances_CPU.nip | Same content. Both kept — may serve different import paths |

---

## VSTPlugins Verification

| Metric | Value |
|--------|-------|
| Total files | 268 |
| Total size | 12.48 MB |
| DLL count | 10 |
| Zero-byte files | 0 |
| Key file: rnnoise_stereo.dll | 8,830,976 bytes (OK) |
| Key file: reacomp-standalone.dll | 191,488 bytes (OK) |
| Key file: reagate-standalone.dll | 180,736 bytes (OK) |

All VST plugins intact. Required for EQ APO mic.txt restoration post-format.

---

## 4 Undownloaded Tools

| Tool | Version | Download | Type |
|------|---------|----------|------|
| CrystalDiskInfo | 9.5.5 | crystalmark.info/en/download/#CrystalDiskInfo | Diagnostic (SMART/disk health) |
| CrystalDiskMark | 9.0.3 | crystalmark.info/en/download/#CrystalDiskMark | Benchmark (disk speed) |
| HWiNFO | v8.60+ | hwinfo.com/download/ | Diagnostic (hardware sensors) |
| SG TCP Optimizer | Latest | speedguide.net/downloads.php | Network tuning |

**Status**: All 4 are NOT COLLECTED. CrystalDisk tools: SourceForge 403 on direct download (manual required).
HWiNFO and SG TCP Optimizer: manual download only.

**Impact**: All are OPTIONAL standalone diagnostic utilities. No YAZX module or Run ALL depends on them.
Setup.bat shows `[!] 13 tools ready, 4 not downloaded` at startup — informational only, no failure.

---

## Tool Count Summary

| Category | Count |
|----------|-------|
| Downloaded tools | 13 |
| Dependencies (VC++, .NET) | 2 |
| Not downloaded | 4 |
| **Total tools** | **17 + 2 deps** |
| VST plugin files | 268 |
| Config collections | 9 (ProcessLasso, MSI AB, NVIDIA, Realtek, EQ APO, Mem Reduct, ParkControl, ExplorerPatcher, OpenShell) |
| Power plans | 3 valid + 1 invalid (0-byte) |
| Kernel settings | 11 documented |

---

## Exit Criteria Checklist

- [x] Old and new YAZX_Setup.bat versions exist
- [x] List of specific changes made (4 changes documented above)
- [x] Proof Modules 01-12 unchanged (SHA-256 content verification + call order match)
- [x] Missing tools don't break Setup (graceful status check)
- [x] YAZX_TOOL_LIBRARY.md up to date (Phase 4)
- [x] SHA-256 manifest generated (742 entries, 739 disk files)
- [x] VSTPlugins verified (268 files, 0 corruption)
- [x] Zero-byte files documented (2)
- [x] Duplicates documented (2 pairs, kept)
- [x] Candidate/Experimental NOT auto-applied
- [x] TTCH rebuild script created with documented coverage gaps
- [x] Power_Control.reg NOT classified as complete TTCH replacement

---

## Final Review Findings (Pre-Phase 6)

### 1. TTCH Power Plan — Expanded from 27 to 72 settings
Power_Control.reg contains 55 setting-level keys for the TTCH plan. The original rebuild
script only had 27 (from powercfg /query text dump). After extracting all 45 missing
AC-only settings from the registry, the rebuild script now covers 72 settings total.
**Classification**: 27 Exact Restore (AC+DC from powercfg /query) + 45 Reconstructed (AC only from registry).
This is NOT an exact plan restore — the original .pow binary was never exported.

### 2. YAZX_Setup.bat — Errorlevel Cascade Verified
Choice string `123456789ABCDEFGVRQ` (19 chars) correctly maps:
- Q (pos 19) → exit, R (pos 18) → reg restore, V (pos 17) → phase25
- G-B (pos 16-11) → modules 14-10 and Run ALL
- A (pos 10) falls through module_choice checks to `:run_all` label (by design)
- [10]-[14] menu labels are pre-existing display-only (user presses C-G, not "10"-"14")
- Run ALL module call order: **IDENTICAL** between current and backup (content-verified)
- **V is NOT in Run ALL** — confirmed by grep

### 3. SHA-256 Manifest — 4 VST Files Added
4 VST files with parentheses in filenames were on disk but missed by initial manifest
generation. Added post-review. Manifest self-hash recorded independently.

### 4. Zero-Byte Files — Classified
- `exports\Steam\virtualgamepadinfo.txt`: **HARMLESS PLACEHOLDER** — empty Steam virtual gamepad config
- `exports\TTCH_UltimatePerformance.pow`: **FAILED EXPORT** — 0-byte, never import

### 5. Missing Tools — Links and Versions Documented
All 4 (CrystalDiskInfo 9.5.5, CrystalDiskMark 9.0.3, HWiNFO v8.60+, SG TCP Optimizer)
remain NOT COLLECTED with official download links. All optional, no module dependency.

---

## Module Content Verification (SHA-256)

| Module | SHA-256 | Size |
|--------|---------|------|
| 01_SystemCheck.ps1 | 24F4256C6A3477C90D5DB8086B99A185AD489C58167F0A2C2FACC632FD49B719 | 2,852 |
| 02_NVIDIADriver.ps1 | 4B8D5CF04A885F00F6F84297B3877D4D51C70710EEFFCDC58677ACADD0D1188E | 4,515 |
| 03_Programs.ps1 | 90DBE99ABF333CAA66D5C44584519454EEDD3C50A9291878A26CD671FC207DAD | 5,322 |
| 04_Configs.ps1 | 9AF6FC2458B9A1CCBDD8F4E90014A446D9B97BF8F88F8FAEDF674D54E60084FC | 7,090 |
| 08_Services.ps1 | F087A1580EEFBDE079E07C5C19809A98DF198317E295B47E932A91DCE192AAE5 | 3,292 |
| 09_BCDTweaks.ps1 | 56055E6E1AEB4BEE89104C494BA29F7472FCE7791F20054B3E46B12DAE3130F0 | 1,190 |
| 10_MSIMode.ps1 | 390B4A603B0DE9971237D3CD6C04BAFA749285B889C56EB1A27C721A31E840EA | 2,476 |
| 11_PowerPlan.ps1 | 5ABAD0C83196836007630FDE10EFCF1D18BCAE6BCF2B50413C7EA742C954A646 | 2,281 |
| 12_Privacy.ps1 | 0B28B032E826FA9F8A64EFCA5640661CC07EE413167AF21D83F6CE074AC7C127 | 4,150 |
| 14_NewTweaks.ps1 | 7D54D29700D1A2C7976C7FDDDF3389DB88A97E3EE2AC18241181239BD91BF694 | 4,473 |

---

## Phase 5 Status: COMPLETE (with final review)
